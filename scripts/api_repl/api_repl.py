#!/usr/bin/env python3
"""Interactive REPL for authenticated API requests to Allama.

Usage:
    uv run scripts/api_repl/api_repl.py
"""

from __future__ import annotations

import code
import os
import sys
from typing import Any

import requests
from rich.console import Console
from rich.panel import Panel
from rich.syntax import Syntax

console = Console()


def print_banner(base_url: str, email: str) -> None:
    banner = f"""[bold cyan]Allama API REPL[/bold cyan]

Authenticated as: [yellow]{email}[/yellow]
Base URL: [yellow]{base_url}[/yellow]

[bold]Available variables:[/bold]
  [cyan]session[/cyan]     - Authenticated requests.Session instance
  [cyan]base_url[/cyan]    - API base URL
  [cyan]service_key[/cyan] - Service key for internal API calls
  [cyan]user_info[/cyan]   - Current user information

[bold]Quick examples:[/bold]
  resp = session.get(f"{{base_url}}/workflows")
  resp = session.post(f"{{base_url}}/workflows", json={{"title": "Test"}})

[dim]Press Ctrl+D or type exit() to quit[/dim]
"""
    console.print(Panel(banner, border_style="blue"))


def create_authenticated_session() -> tuple[requests.Session, str, dict[str, Any]]:
    """Create and return (session, base_url, user_info)."""
    base_url = os.environ.get("ALLAMA__PUBLIC_API_URL", "http://localhost/api")
    email = os.environ.get("ALLAMA__TEST_USER_EMAIL", "test@allama.com")
    password = os.environ.get("ALLAMA__TEST_USER_PASSWORD", "password1234")

    console.print("[yellow]Initialising session...[/yellow]")
    session = requests.Session()

    console.print(f"[dim]Registering {email}...[/dim]")
    register_response = session.post(
        f"{base_url}/auth/register",
        json={"email": email, "password": password},
    )

    if register_response.status_code == 201:
        console.print("[green]Registered test user[/green]")
    elif register_response.status_code in [400, 409]:
        console.print("[dim]Test user already exists[/dim]")
    else:
        console.print(
            f"[red]Registration returned unexpected status: "
            f"{register_response.status_code} - {register_response.text}[/red]",
        )
        sys.exit(1)

    # Login
    console.print(f"[dim]Logging in as {email}...[/dim]")
    login_response = session.post(
        f"{base_url}/auth/login",
        data={"username": email, "password": password},
    )

    if login_response.status_code != 204:
        console.print(f"[red]Login failed: {login_response.text}[/red]")
        sys.exit(1)

    console.print("[green]Authenticated[/green]\n")

    # User info
    user_response = session.get(f"{base_url}/users/me")
    user_info = user_response.json() if user_response.status_code == 200 else {}

    return session, base_url, user_info


def start_repl(
    session: requests.Session,
    base_url: str,
    user_info: dict[str, Any],
) -> None:
    service_key = os.environ.get("ALLAMA__SERVICE_KEY")

    print_banner(base_url, user_info.get("email", "unknown"))

    repl_namespace = {
        "session": session,
        "base_url": base_url,
        "user_info": user_info,
        "service_key": service_key,
        "requests": requests,
        "console": console,
    }

    # Helpers
    def pretty_json(data: Any) -> None:
        import json

        syntax = Syntax(
            json.dumps(data, indent=2),
            "json",
            theme="monokai",
            line_numbers=False,
        )
        console.print(syntax)

    def help_commands() -> None:
        help_text = """[bold]Available helper functions:[/bold]

  [cyan]pretty_json(data)[/cyan]     - Pretty print JSON with syntax highlighting
  [cyan]help_commands()[/cyan]       - Show this help message

[bold]Common API patterns:[/bold]

  # List workflows
  resp = session.get(f"{base_url}/workflows")
  pretty_json(resp.json())

  # Create workflow
  resp = session.post(f"{base_url}/workflows", json={
      "title": "My Workflow",
      "description": "Test workflow"
  })

  # Get workflow by ID
  workflow_id = "wf_..."
  resp = session.get(f"{base_url}/workflows/{workflow_id}")

  # List secrets
  resp = session.get(f"{base_url}/organization/secrets")

  # List registry repositories
  resp = session.get(f"{base_url}/registry/repos")
"""
        console.print(Panel(help_text, border_style="blue", title="Help"))

    repl_namespace["pretty_json"] = pretty_json
    repl_namespace["help_commands"] = help_commands

    try:
        code.interact(
            banner="",
            local=repl_namespace,
            exitmsg="\n[yellow]Goodbye![/yellow]",
        )
    except (EOFError, KeyboardInterrupt):
        console.print("\n[yellow]Goodbye![/yellow]")


def main() -> None:
    """Main entry point."""
    try:
        session, base_url, user_info = create_authenticated_session()
        start_repl(session, base_url, user_info)
    except KeyboardInterrupt:
        console.print("\n[yellow]Interrupted. Goodbye![/yellow]")
        sys.exit(0)
    except Exception as e:
        console.print(f"[red]Error:[/red] {e}", style="red")
        sys.exit(1)


if __name__ == "__main__":
    main()
