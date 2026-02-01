# Requirements Document

## Introduction

This document specifies the requirements for implementing a dark theme feature in the Allama frontend application. The frontend is a Next.js 15 application using shadcn/ui components with Tailwind CSS. The infrastructure for dark mode already exists (CSS variables defined in globals.scss, darkMode: ["class"] in tailwind.config.js, next-themes package installed), but the ThemeProvider and theme toggle are not implemented.

## Glossary

- **Theme_Provider**: A React context provider component from next-themes that manages theme state and applies the appropriate class to the document
- **Theme_Toggle**: A UI component that allows users to switch between Light, Dark, and System theme modes
- **CSS_Variable**: A custom property defined in CSS that can be referenced throughout stylesheets, enabling dynamic theming
- **System_Theme**: The theme preference detected from the user's operating system settings
- **Hardcoded_Color**: A Tailwind CSS class that specifies a fixed color value (e.g., bg-white, text-black) rather than using CSS variables

## Requirements

### Requirement 1: Theme Provider Setup

**User Story:** As a user, I want the application to support theme switching, so that I can use the app in my preferred color scheme.

#### Acceptance Criteria

1. THE Theme_Provider SHALL wrap the application at the root layout level
2. THE Theme_Provider SHALL use the "class" attribute strategy for theme application
3. THE Theme_Provider SHALL default to "system" theme when no preference is stored
4. THE Theme_Provider SHALL persist theme preference across page refreshes using local storage
5. THE Theme_Provider SHALL suppress hydration warnings to prevent flash of incorrect theme

### Requirement 2: Theme Toggle Component

**User Story:** As a user, I want a theme toggle control in the UI, so that I can easily switch between light, dark, and system themes.

#### Acceptance Criteria

1. THE Theme_Toggle SHALL be positioned in the top-right area of the UI header
2. THE Theme_Toggle SHALL display a dropdown menu with three options: Light, Dark, and System
3. WHEN the user selects Light mode, THE Theme_Toggle SHALL apply the light theme immediately
4. WHEN the user selects Dark mode, THE Theme_Toggle SHALL apply the dark theme immediately
5. WHEN the user selects System mode, THE Theme_Toggle SHALL apply the theme matching the user's OS preference
6. THE Theme_Toggle SHALL display appropriate icons (Sun for light, Moon for dark) to indicate the current theme
7. THE Theme_Toggle SHALL indicate the currently active theme option in the dropdown

### Requirement 3: Button Component Color Migration

**User Story:** As a user, I want all buttons to be properly styled in both themes, so that they remain visible and usable regardless of theme.

#### Acceptance Criteria

1. WHEN a button uses bg-white class, THE System SHALL replace it with bg-background or bg-card class
2. THE System SHALL ensure all outline variant buttons are visible in both light and dark themes
3. THE System SHALL maintain consistent button styling across the following components:
   - controls-header.tsx (Tables, Integrations, Agents, Cases action buttons)
   - add-workspace-member.tsx
   - create-workflow-button.tsx
   - add-custom-field.tsx
   - add-case-duration.tsx
   - add-case-tag.tsx
   - table-insert-button.tsx
   - create-custom-provider-dialog.tsx
   - mcp-integration-dialog.tsx

### Requirement 4: Badge Component Color Migration

**User Story:** As a user, I want badges to be readable in both themes, so that status indicators remain clear.

#### Acceptance Criteria

1. WHEN the ComingSoonBadge uses bg-white class, THE System SHALL replace it with bg-background class
2. THE System SHALL ensure badge text remains readable against the background in both themes

### Requirement 5: Sidebar Component Color Migration

**User Story:** As a user, I want the sidebar to adapt to the current theme, so that navigation remains comfortable in both light and dark modes.

#### Acceptance Criteria

1. WHEN the sidebar uses bg-zinc-50 class, THE System SHALL replace it with bg-sidebar class
2. WHEN the sidebar uses dark:bg-zinc-950 class, THE System SHALL ensure it uses the CSS variable-based dark variant
3. THE SidebarProvider SHALL use bg-sidebar for the inset variant background
4. THE Sidebar mobile sheet SHALL use bg-sidebar for consistent theming
5. THE SidebarInset border SHALL use border-border class instead of hardcoded zinc colors

### Requirement 6: Landing Page Color Migration

**User Story:** As a user, I want the landing page to display correctly in both themes, so that my first impression of the app is positive regardless of my theme preference.

#### Acceptance Criteria

1. WHEN the landing page hero section uses bg-zinc-900, THE System SHALL use bg-foreground or an appropriate dark background that works in both themes
2. WHEN text-white is used for intentional contrast on dark backgrounds, THE System SHALL preserve this styling
3. THE System SHALL ensure the landing page maintains visual hierarchy in both themes

### Requirement 7: Cases Feed Event Color Migration

**User Story:** As a user, I want case feed events to be visible in both themes, so that I can track case activity clearly.

#### Acceptance Criteria

1. WHEN the cases-feed-event.tsx uses bg-white for event indicators, THE System SHALL replace it with bg-background class

### Requirement 8: Visual Regression Prevention

**User Story:** As a developer, I want to ensure no visual regressions occur after the theme migration, so that the user experience remains consistent.

#### Acceptance Criteria

1. THE System SHALL ensure all text remains readable in both light and dark themes
2. THE System SHALL ensure all borders are visible in both themes
3. THE System SHALL ensure all interactive elements have appropriate hover and focus states in both themes
4. THE System SHALL ensure popovers, dropdowns, and modals adapt correctly to the current theme
5. THE System SHALL ensure form inputs have appropriate contrast in both themes
