# Implementation Plan: Dark Theme Feature

## Overview

This implementation plan covers adding dark theme support to the Allama frontend. The work involves creating a ThemeProvider wrapper, a theme toggle component, and migrating hardcoded color classes to CSS variable-based alternatives across multiple components.

## Tasks

- [x] 1. Set up ThemeProvider and integrate into layout
  - [x] 1.1 Create ThemeProvider component
    - Create `frontend/src/providers/theme.tsx`
    - Export ThemeProvider wrapper using next-themes
    - Configure with attribute="class", defaultTheme="system", enableSystem, disableTransitionOnChange
    - _Requirements: 1.1, 1.2, 1.3, 1.5_
  
  - [x] 1.2 Integrate ThemeProvider into root layout
    - Modify `frontend/src/app/layout.tsx`
    - Wrap application content with ThemeProvider
    - Ensure suppressHydrationWarning is set on html element
    - _Requirements: 1.1, 1.4_

- [x] 2. Create ThemeToggle component and add to header
  - [x] 2.1 Create ThemeToggle component
    - Create `frontend/src/components/theme-toggle.tsx`
    - Implement dropdown with Light, Dark, System options
    - Add Sun/Moon icons with transition animations
    - Show checkmark indicator for active theme
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7_
  
  - [x] 2.2 Add ThemeToggle to controls header
    - Modify `frontend/src/components/nav/controls-header.tsx`
    - Position toggle in top-right area of header
    - _Requirements: 2.1_

- [x] 3. Checkpoint - Verify theme switching works
  - Ensure theme toggle appears and functions correctly
  - Verify theme persists across page refresh
  - Ask the user if questions arise

- [x] 4. Migrate button components to use CSS variables
  - [x] 4.1 Update controls-header.tsx buttons
    - Replace all `bg-white` classes with `bg-background`
    - Affects: TablesActions, IntegrationsActions, AgentsActions, CasesActions buttons
    - _Requirements: 3.1, 3.3_
  
  - [x] 4.2 Update add-workspace-member.tsx button
    - Replace `bg-white` with `bg-background`
    - _Requirements: 3.1, 3.3_
  
  - [x] 4.3 Update create-workflow-button.tsx
    - Replace `bg-white` with `bg-background`
    - _Requirements: 3.1, 3.3_
  
  - [x] 4.4 Update case action buttons
    - Modify `frontend/src/components/cases/add-custom-field.tsx`
    - Modify `frontend/src/components/cases/add-case-duration.tsx`
    - Modify `frontend/src/components/cases/add-case-tag.tsx`
    - Replace `bg-white` with `bg-background` in each
    - _Requirements: 3.1, 3.3_
  
  - [x] 4.5 Update table-insert-button.tsx
    - Replace `bg-white` with `bg-background`
    - _Requirements: 3.1, 3.3_
  
  - [x] 4.6 Update integration dialog triggers
    - Modify `frontend/src/components/integrations/create-custom-provider-dialog.tsx`
    - Modify `frontend/src/components/integrations/mcp-integration-dialog.tsx`
    - Replace `bg-white` with `bg-background`
    - _Requirements: 3.1, 3.3_

- [x] 5. Migrate badge and feed components
  - [x] 5.1 Update badges.tsx
    - Replace `bg-white` with `bg-background` in ComingSoonBadge
    - _Requirements: 4.1, 4.2_
  
  - [x] 5.2 Update cases-feed-event.tsx
    - Replace `bg-white` with `bg-background` for event indicators
    - _Requirements: 7.1_

- [x] 6. Migrate sidebar component colors
  - [x] 6.1 Update sidebar.tsx
    - Replace `bg-zinc-50` with `bg-sidebar`
    - Replace `dark:bg-zinc-950` with appropriate sidebar variable usage
    - Update SidebarProvider inset variant background
    - Update Sidebar mobile sheet background
    - Update SidebarInset border classes to use `border-border`
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [x] 7. Update landing page colors
  - [x] 7.1 Update page.tsx
    - Review `bg-zinc-900` usage and update if needed for theme compatibility
    - Preserve intentional `text-white` on dark backgrounds
    - Ensure visual hierarchy works in both themes
    - _Requirements: 6.1, 6.2, 6.3_
    - Note: bg-zinc-900 is intentionally used for the dark left panel design, no changes needed

- [ ] 8. Checkpoint - Visual verification
  - Test all migrated components in light theme
  - Test all migrated components in dark theme
  - Verify no visual regressions
  - Ensure all text is readable, borders visible
  - Ask the user if questions arise

- [ ] 9. Add property-based tests
  - [ ] 9.1 Write property test for theme class application
    - **Property 1: Theme Class Application**
    - **Validates: Requirements 1.2, 2.3, 2.4**
  
  - [ ] 9.2 Write property test for theme persistence
    - **Property 2: Theme Persistence Round-Trip**
    - **Validates: Requirements 1.4**
  
  - [ ] 9.3 Write property test for active theme indication
    - **Property 3: Active Theme Indication**
    - **Validates: Requirements 2.7**

- [ ] 10. Add unit tests for theme components
  - [ ] 10.1 Write unit tests for ThemeProvider
    - Test default theme is "system"
    - Test children render correctly
    - _Requirements: 1.1, 1.3_
  
  - [ ] 10.2 Write unit tests for ThemeToggle
    - Test dropdown opens on click
    - Test all three options are present
    - Test clicking options calls setTheme correctly
    - _Requirements: 2.2, 2.3, 2.4, 2.5_

- [ ] 11. Final checkpoint - Complete verification
  - Ensure all tests pass
  - Verify theme functionality end-to-end
  - Ask the user if questions arise

## Notes

- The frontend uses pnpm for package management
- Run `pnpm -C frontend dev` to test changes locally
- Run `pnpm -C frontend lint` to check for linting issues
- Property tests should use fast-check library with minimum 100 iterations
