import type {
  JSONSchema7,
  JSONSchema7Definition,
  JSONSchema7Type,
} from "json-schema"
import type { EditorComponent } from "@/client"

/* expression component */

export type ExpressionComponent = {
  component_id: "expression"
}

export type AllamaEditorComponent = EditorComponent | ExpressionComponent
export type AllamaComponentId = NonNullable<
  AllamaEditorComponent["component_id"]
>

export type AllamaJsonSchema = JSONSchema7 & TcJsonSchemaExtra
export type AllamaJsonSchemaDefinition = JSONSchema7Definition &
  TcJsonSchemaExtra
export type AllamaJsonSchemaType = JSONSchema7Type & TcJsonSchemaExtra
export const ALLAMA_COMPONENT_KEY = "x-allama-component" as const

export type TcJsonSchemaExtra = {
  [ALLAMA_COMPONENT_KEY]?: AllamaEditorComponent[]
}

export function isAllamaJsonSchema(
  schema: unknown
): schema is AllamaJsonSchema {
  return (
    typeof schema === "object" &&
    schema !== null &&
    ALLAMA_COMPONENT_KEY in schema
  )
}

// Helper function to get components as array
/**
 * Returns the Allama components array from the schema.
 * If the component key is not present or not an array, returns an empty array.
 * Only returns the value if it is an array.
 *
 * @param schema - The AllamaJsonSchema object to extract components from.
 * @returns An array of component objects with at least a component_id.
 */
/**
 * Type guard to check if an object is a valid Allama component.
 * A valid component must be a non-null object with a string 'component_id' property.
 *
 * @param item - The item to check.
 * @returns True if the item is a valid Allama component, false otherwise.
 */
export function isAllamaComponent(
  item: unknown
): item is AllamaEditorComponent {
  return (
    typeof item === "object" &&
    item !== null &&
    "component_id" in item &&
    typeof (item as { component_id: unknown }).component_id === "string"
  )
}

/**
 * Returns the Allama components array from the schema.
 * If the component key is not present or not an array, returns an empty array.
 * Only returns the value if it is an array of valid Allama components.
 *
 * @param schema - The AllamaJsonSchema object to extract components from.
 * @returns An array of component objects with at least a component_id.
 */
export function getAllamaComponents(
  schema: AllamaJsonSchema
): AllamaEditorComponent[] {
  const component = schema[ALLAMA_COMPONENT_KEY]
  if (Array.isArray(component)) {
    // Use the type guard to filter valid components
    return component.filter(isAllamaComponent)
  }
  return []
}

// Helper function to check if schema has multiple components
export function hasMultipleComponents(schema: AllamaJsonSchema): boolean {
  const component = schema[ALLAMA_COMPONENT_KEY]
  return Array.isArray(component) && component.length > 1
}
