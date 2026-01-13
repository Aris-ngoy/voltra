import React, { ElementType, Suspense } from 'react'

import { Voltra } from '../../server.js'
import { renderVoltraVariantToJson } from '../renderer.js'

describe('renderVoltraVariantToJson', () => {
  test('Simple text component', () => {
    const element = <Voltra.Text>Hello, world!</Voltra.Text>
    const result = renderVoltraVariantToJson(element)
    expect(result).toEqual({ t: 0, c: 'Hello, world!' })
  })

  test('Nested components', () => {
    const element = (
      <Voltra.VStack>
        <Voltra.Text>Element 1</Voltra.Text>
        <Voltra.Text>Element 2</Voltra.Text>
      </Voltra.VStack>
    )
    const result = renderVoltraVariantToJson(element)
    expect(result).toEqual({
      t: 11,
      c: [
        { t: 0, c: 'Element 1' },
        { t: 0, c: 'Element 2' },
      ],
    })
  })

  describe('Text', () => {
    test('Simple text component', () => {
      const element = <Voltra.Text>Hello, world!</Voltra.Text>
      const result = renderVoltraVariantToJson(element)
      expect(result).toEqual({ t: 0, c: 'Hello, world!' })
    })

    test('Does not allow nested components', () => {
      const element = (
        <Voltra.Text>
          <Voltra.Text>Hello, world!</Voltra.Text>
        </Voltra.Text>
      )
      expect(() => renderVoltraVariantToJson(element)).toThrow('Text component children must resolve to a string.')
    })

    test('Stringifies number children', () => {
      const element = <Voltra.Text>{42}</Voltra.Text>
      const result = renderVoltraVariantToJson(element)
      expect(result).toEqual({ t: 0, c: '42' })
    })

    test('Stringifies bigint children', () => {
      const element = <Voltra.Text>{123n}</Voltra.Text>
      const result = renderVoltraVariantToJson(element)
      expect(result).toEqual({ t: 0, c: '123' })
    })
  })

  test('Component triggering suspense', () => {
    const SuspenseComponent = () => {
      throw new Promise(() => {})
    }

    const element = <SuspenseComponent />
    expect(() => renderVoltraVariantToJson(element)).toThrow(
      'Component "SuspenseComponent" suspended! Voltra does not support Suspense/Promises.'
    )
  })

  test('Async component returning promise', () => {
    const AsyncComponent = async () => {
      await new Promise((resolve) => setTimeout(resolve, 100))
      return 'Async result'
    }

    const element = <AsyncComponent />
    expect(() => renderVoltraVariantToJson(element)).toThrow(
      'Component "AsyncComponent" tried to suspend (returned a Promise). Async components are not supported in this synchronous renderer.'
    )
  })

  test('Class component', () => {
    class ClassComponent extends React.Component {
      render() {
        return 'Hello'
      }
    }

    const element = <ClassComponent />
    expect(() => renderVoltraVariantToJson(element)).toThrow('Class components are not supported in Voltra.')
  })

  test('Context providers', () => {
    const TestContext = React.createContext('default')

    const element = (
      <TestContext.Provider value="provided">
        <TestContext.Consumer>{(value) => <Voltra.Text>{value}</Voltra.Text>}</TestContext.Consumer>
      </TestContext.Provider>
    )

    const result = renderVoltraVariantToJson(element)
    expect(result).toEqual({ t: 0, c: 'provided' })
  })

  test('Context consumers', () => {
    const TestContext = React.createContext('default')

    const element = (
      <TestContext.Provider value="from provider">
        <TestContext.Consumer>{(value) => <Voltra.Text>Consumed: {value}</Voltra.Text>}</TestContext.Consumer>
      </TestContext.Provider>
    )

    const result = renderVoltraVariantToJson(element)
    expect(result).toEqual({ t: 0, c: 'Consumed: from provider' })
  })

  test('Context consumers with default values', () => {
    const TestContext = React.createContext('default value')

    const element = <TestContext.Consumer>{(value) => <Voltra.Text>{value}</Voltra.Text>}</TestContext.Consumer>

    const result = renderVoltraVariantToJson(element)
    expect(result).toEqual({ t: 0, c: 'default value' })
  })

  test('Suspense component', () => {
    const element = <Suspense>In suspense</Suspense>
    expect(() => renderVoltraVariantToJson(element)).toThrow('Suspense is not supported in Voltra.')
  })

  test('Portal component', () => {
    const Portal = Symbol.for('react.portal') as unknown as ElementType
    const element = <Portal>Portal content</Portal>

    expect(() => renderVoltraVariantToJson(element)).toThrow('Portal is not supported in Voltra.')
  })

  test('Profiler component', () => {
    const element = React.createElement(
      React.Profiler,
      {
        id: 'test',
        onRender: () => {},
      },
      <Voltra.Text>Profiled content</Voltra.Text>
    )

    expect(() => renderVoltraVariantToJson(element)).toThrow('Profiler is not supported in Voltra.')
  })

  test('Nested fragments', () => {
    const element = (
      <>
        <Voltra.Text>Element 1</Voltra.Text>
        <>
          <Voltra.Text>Element 2</Voltra.Text>
          <Voltra.Text>Element 3</Voltra.Text>
        </>
      </>
    )
    const result = renderVoltraVariantToJson(element)

    expect(result).toEqual([
      { t: 0, c: 'Element 1' },
      { t: 0, c: 'Element 2' },
      { t: 0, c: 'Element 3' },
    ])
  })
})
