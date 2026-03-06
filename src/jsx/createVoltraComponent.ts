import type { ComponentType } from 'react'
import { createElement } from 'react'

export const VOLTRA_COMPONENT_TAG = Symbol.for('VOLTRA_COMPONENT_TAG')

export type VoltraComponent<TProps extends Record<string, unknown>> = ComponentType<TProps> & {
  displayName: string
  [VOLTRA_COMPONENT_TAG]: true
}

export type VoltraComponentOptions<TProps extends Record<string, unknown>> = {
  toJSON?: (props: TProps) => Record<string, unknown>
}

export const createVoltraComponent = <TProps extends Record<string, unknown>>(
  componentName: string,
  options?: VoltraComponentOptions<TProps>
): VoltraComponent<TProps> => {
  const Component = (props: TProps) => {
    const toJSON = options?.toJSON ? options.toJSON : (props: TProps) => props
    const normalizedProps = toJSON(props)

    return createElement(componentName, normalizedProps)
  }

  const taggedComponent = Component as unknown as VoltraComponent<TProps>
  taggedComponent[VOLTRA_COMPONENT_TAG] = true
  taggedComponent.displayName = componentName

  return taggedComponent
}

export const isVoltraComponent = <TProps extends Record<string, unknown>>(
  component: ComponentType<TProps>
): component is VoltraComponent<TProps> => {
  return typeof component === 'function' && VOLTRA_COMPONENT_TAG in component
}
