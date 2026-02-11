"""Benchmark: ThreadPool vs Sequential vs AsyncConcurrent for mixed CPU/IO workloads."""

from __future__ import annotations

import asyncio
import hashlib
import json
import statistics
import threading
import time
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from http.server import BaseHTTPRequestHandler, HTTPServer
from typing import Any

import httpx
import uvloop

# Use uvloop for better async performance
asyncio.set_event_loop_policy(uvloop.EventLoopPolicy())

HTTP_SERVER_PORT = 18765
HTTP_SERVER_DELAY_MS = 200
NUM_WORKERS = 4
THREADS_PER_WORKER = 4
NUM_TASKS = 50
CPU_WORK_ITERATIONS = 50000


@dataclass
class BenchmarkResult:
    name: str
    total_time_ms: float
    tasks_per_second: float
    avg_task_time_ms: float
    p50_ms: float
    p95_ms: float
    p99_ms: float
    task_times: list[float]


class DelayedHandler(BaseHTTPRequestHandler):
    """HTTP handler with artificial delay to simulate network latency."""

    def do_GET(self):
        time.sleep(HTTP_SERVER_DELAY_MS / 1000)
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(b'{"status": "ok", "data": "response"}')

    def log_message(self, format, *args):
        pass


def start_http_server():
    server = HTTPServer(("127.0.0.1", HTTP_SERVER_PORT), DelayedHandler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    print(f"Mock HTTP server started on port {HTTP_SERVER_PORT}")
    return server


def cpu_work(iterations: int = CPU_WORK_ITERATIONS) -> str:
    """Simulate CPU-bound work (hashing, JSON serialisation)."""
    data = {"key": "value", "numbers": list(range(100))}
    result = ""
    for _ in range(iterations):
        json_str = json.dumps(data)
        result = hashlib.sha256(json_str.encode()).hexdigest()
    return result


async def io_work(client: httpx.AsyncClient) -> dict[str, Any]:
    """Simulate IO-bound work (HTTP request)."""
    response = await client.get(f"http://127.0.0.1:{HTTP_SERVER_PORT}/api/data")
    return response.json()


async def mixed_task(client: httpx.AsyncClient, task_id: int) -> dict[str, Any]:
    """Run a task that mixes CPU and IO work."""
    start = time.perf_counter()

    cpu_result = cpu_work()
    io_result = await io_work(client)
    cpu_work(iterations=CPU_WORK_ITERATIONS // 2)

    elapsed_ms = (time.perf_counter() - start) * 1000

    return {
        "task_id": task_id,
        "elapsed_ms": elapsed_ms,
        "cpu_hash": cpu_result[:8],
        "io_status": io_result.get("status"),
    }


class ThreadPoolWorker:
    """Worker using ThreadPoolExecutor with per-thread event loops."""

    def __init__(self, num_threads: int = THREADS_PER_WORKER):
        self.executor = ThreadPoolExecutor(max_workers=num_threads)
        self._thread_local = threading.local()

    def _get_thread_loop(self) -> asyncio.AbstractEventLoop:
        if (
            not hasattr(self._thread_local, "loop")
            or self._thread_local.loop.is_closed()
        ):
            self._thread_local.loop = asyncio.new_event_loop()
            asyncio.set_event_loop(self._thread_local.loop)
        return self._thread_local.loop

    def _get_thread_client(self) -> httpx.AsyncClient:
        if not hasattr(self._thread_local, "client"):
            self._thread_local.client = httpx.AsyncClient()
        return self._thread_local.client

    def _run_task_sync(self, task_id: int) -> dict[str, Any]:
        loop = self._get_thread_loop()
        client = self._get_thread_client()
        return loop.run_until_complete(mixed_task(client, task_id))

    async def run_tasks(self, task_ids: list[int]) -> list[dict[str, Any]]:
        """Run tasks concurrently via thread pool."""
        loop = asyncio.get_event_loop()
        futures = [
            loop.run_in_executor(self.executor, self._run_task_sync, task_id)
            for task_id in task_ids
        ]
        return await asyncio.gather(*futures)

    def shutdown(self):
        self.executor.shutdown(wait=True)


class SequentialWorker:
    """Worker that runs tasks sequentially on the main event loop."""

    def __init__(self):
        self.client: httpx.AsyncClient | None = None

    async def _ensure_client(self) -> httpx.AsyncClient:
        if self.client is None:
            self.client = httpx.AsyncClient()
        return self.client

    async def run_tasks(self, task_ids: list[int]) -> list[dict[str, Any]]:
        """Run tasks one at a time."""
        client = await self._ensure_client()
        results = []
        for task_id in task_ids:
            result = await mixed_task(client, task_id)
            results.append(result)
        return results

    async def shutdown(self):
        if self.client:
            await self.client.aclose()


class AsyncConcurrentWorker:
    """Worker that runs tasks concurrently via asyncio.gather on one loop."""

    def __init__(self, max_concurrent: int = THREADS_PER_WORKER):
        self.semaphore = asyncio.Semaphore(max_concurrent)
        self.client: httpx.AsyncClient | None = None

    async def _ensure_client(self) -> httpx.AsyncClient:
        if self.client is None:
            self.client = httpx.AsyncClient()
        return self.client

    async def _run_with_semaphore(
        self, client: httpx.AsyncClient, task_id: int
    ) -> dict[str, Any]:
        async with self.semaphore:
            return await mixed_task(client, task_id)

    async def run_tasks(self, task_ids: list[int]) -> list[dict[str, Any]]:
        """Run tasks concurrently via asyncio.gather (limited by semaphore)."""
        client = await self._ensure_client()
        tasks = [self._run_with_semaphore(client, task_id) for task_id in task_ids]
        return await asyncio.gather(*tasks)

    async def shutdown(self):
        if self.client:
            await self.client.aclose()


def calculate_percentile(data: list[float], percentile: float) -> float:
    sorted_data = sorted(data)
    index = int(len(sorted_data) * percentile / 100)
    return sorted_data[min(index, len(sorted_data) - 1)]


async def benchmark_threadpool(num_tasks: int) -> BenchmarkResult:
    worker = ThreadPoolWorker(num_threads=THREADS_PER_WORKER)
    task_ids = list(range(num_tasks))

    start = time.perf_counter()
    results = await worker.run_tasks(task_ids)
    total_time_ms = (time.perf_counter() - start) * 1000

    worker.shutdown()

    task_times = [r["elapsed_ms"] for r in results]

    return BenchmarkResult(
        name="ThreadPool",
        total_time_ms=total_time_ms,
        tasks_per_second=num_tasks / (total_time_ms / 1000),
        avg_task_time_ms=statistics.mean(task_times),
        p50_ms=calculate_percentile(task_times, 50),
        p95_ms=calculate_percentile(task_times, 95),
        p99_ms=calculate_percentile(task_times, 99),
        task_times=task_times,
    )


async def benchmark_sequential(num_tasks: int) -> BenchmarkResult:
    worker = SequentialWorker()
    task_ids = list(range(num_tasks))

    start = time.perf_counter()
    results = await worker.run_tasks(task_ids)
    total_time_ms = (time.perf_counter() - start) * 1000

    await worker.shutdown()

    task_times = [r["elapsed_ms"] for r in results]

    return BenchmarkResult(
        name="Sequential",
        total_time_ms=total_time_ms,
        tasks_per_second=num_tasks / (total_time_ms / 1000),
        avg_task_time_ms=statistics.mean(task_times),
        p50_ms=calculate_percentile(task_times, 50),
        p95_ms=calculate_percentile(task_times, 95),
        p99_ms=calculate_percentile(task_times, 99),
        task_times=task_times,
    )


async def benchmark_async_concurrent(num_tasks: int) -> BenchmarkResult:
    worker = AsyncConcurrentWorker(max_concurrent=THREADS_PER_WORKER)
    task_ids = list(range(num_tasks))

    start = time.perf_counter()
    results = await worker.run_tasks(task_ids)
    total_time_ms = (time.perf_counter() - start) * 1000

    await worker.shutdown()

    task_times = [r["elapsed_ms"] for r in results]

    return BenchmarkResult(
        name="AsyncConcurrent",
        total_time_ms=total_time_ms,
        tasks_per_second=num_tasks / (total_time_ms / 1000),
        avg_task_time_ms=statistics.mean(task_times),
        p50_ms=calculate_percentile(task_times, 50),
        p95_ms=calculate_percentile(task_times, 95),
        p99_ms=calculate_percentile(task_times, 99),
        task_times=task_times,
    )


def print_result(result: BenchmarkResult):
    print(f"\n{'=' * 60}")
    print(f"  {result.name}")
    print(f"{'=' * 60}")
    print(f"  Total time:        {result.total_time_ms:>10.1f} ms")
    print(f"  Tasks/second:      {result.tasks_per_second:>10.1f}")
    print(f"  Avg task time:     {result.avg_task_time_ms:>10.1f} ms")
    print(f"  P50 latency:       {result.p50_ms:>10.1f} ms")
    print(f"  P95 latency:       {result.p95_ms:>10.1f} ms")
    print(f"  P99 latency:       {result.p99_ms:>10.1f} ms")


async def main():
    print("=" * 60)
    print("  Pool Benchmark: ThreadPool vs Sequential vs AsyncConcurrent")
    print("=" * 60)
    print("\nConfiguration:")
    print(f"  - Tasks: {NUM_TASKS}")
    print(f"  - Threads per worker: {THREADS_PER_WORKER}")
    print(f"  - HTTP delay: {HTTP_SERVER_DELAY_MS}ms")
    print(f"  - CPU iterations: {CPU_WORK_ITERATIONS}")

    # Start mock HTTP server
    server = start_http_server()
    await asyncio.sleep(0.5)

    # Warmup
    print("\nWarmup...")
    await benchmark_threadpool(10)
    await benchmark_sequential(10)
    await benchmark_async_concurrent(10)

    # Run benchmarks
    print(f"\nRunning benchmarks with {NUM_TASKS} tasks each...")

    results = []

    print("\n[1/3] Running ThreadPool benchmark...")
    results.append(await benchmark_threadpool(NUM_TASKS))

    print("[2/3] Running Sequential benchmark...")
    results.append(await benchmark_sequential(NUM_TASKS))

    print("[3/3] Running AsyncConcurrent benchmark...")
    results.append(await benchmark_async_concurrent(NUM_TASKS))

    # Print results
    print("\n" + "=" * 60)
    print("  RESULTS")
    print("=" * 60)

    for result in results:
        print_result(result)

    # Comparison
    threadpool = results[0]
    sequential = results[1]
    async_concurrent = results[2]

    print(f"\n{'=' * 60}")
    print("  COMPARISON")
    print(f"{'=' * 60}")
    print("\n  ThreadPool vs Sequential:")
    speedup = sequential.total_time_ms / threadpool.total_time_ms
    print(f"    Speedup: {speedup:.2f}x {'faster' if speedup > 1 else 'slower'}")

    print("\n  AsyncConcurrent vs Sequential:")
    speedup2 = sequential.total_time_ms / async_concurrent.total_time_ms
    print(f"    Speedup: {speedup2:.2f}x {'faster' if speedup2 > 1 else 'slower'}")

    print("\n  ThreadPool vs AsyncConcurrent:")
    speedup3 = async_concurrent.total_time_ms / threadpool.total_time_ms
    print(f"    Speedup: {speedup3:.2f}x {'faster' if speedup3 > 1 else 'slower'}")

    print("\n" + "=" * 60)
    print("  ANALYSIS")
    print("=" * 60)
    print("""
  - ThreadPool: True parallelism for CPU work (GIL released during IO)
  - Sequential: No parallelism, tasks run one at a time
  - AsyncConcurrent: IO parallelism only (CPU blocks all tasks)

  ThreadPool wins when tasks have significant CPU work mixed with IO.
  AsyncConcurrent is simpler but CPU work blocks other tasks.
  Sequential is simplest but has no parallelism.
""")

    server.shutdown()


if __name__ == "__main__":
    asyncio.run(main())
