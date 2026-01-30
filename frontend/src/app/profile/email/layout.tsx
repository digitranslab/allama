import type { Metadata } from "next"

export const metadata: Metadata = {
  title: "Email Settings | Allama",
}

export default function EmailLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return children
}
