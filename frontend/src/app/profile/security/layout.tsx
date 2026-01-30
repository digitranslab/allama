import type { Metadata } from "next"

export const metadata: Metadata = {
  title: "Security | Allama",
}

export default function SecurityLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return children
}
