import type { Metadata } from "next"

export const metadata: Metadata = {
  title: "Profile Settings | Allama",
}

export default function ProfileSettingsLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return children
}
