import React from 'react'
import { Voltra } from 'voltra'

/**
 * Simple Timer Live Activity - Lock Screen view
 */
export function TimerLockScreen() {
  return (
    <Voltra.VStack id="timer-live-activity" spacing={8} style={{ padding: 16 }}>
      <Voltra.HStack>
        <Voltra.Symbol name="timer" tintColor="#FFFFFF" size={16} />
        <Voltra.Text
          style={{
            color: '#FFFFFF',
            fontSize: 18,
            fontWeight: '600',
            marginLeft: 8,
          }}
        >
          Timer
        </Voltra.Text>
        <Voltra.Spacer />
        <Voltra.Text
          style={{
            color: '#94A3B8',
            fontSize: 14,
          }}
        >
          Running
        </Voltra.Text>
      </Voltra.HStack>

      <Voltra.HStack>
        <Voltra.Text
          style={{
            color: '#FFFFFF',
            fontSize: 48,
            fontWeight: '700',
            letterSpacing: -2,
          }}
        >
          05:00
        </Voltra.Text>
        <Voltra.Spacer />
        <Voltra.VStack alignment="trailing">
          <Voltra.Text
            style={{
              color: '#34D399',
              fontSize: 14,
              fontWeight: '500',
            }}
          >
            Remaining
          </Voltra.Text>
        </Voltra.VStack>
      </Voltra.HStack>
    </Voltra.VStack>
  )
}

/**
 * Dynamic Island - Minimal view (pill on the right)
 */
export function TimerIslandMinimal() {
  return (
    <Voltra.Text
      style={{
        color: '#FFFFFF',
        fontSize: 12,
        fontWeight: '600',
      }}
    >
      5:00
    </Voltra.Text>
  )
}

/**
 * Dynamic Island - Compact Leading (left side)
 */
export function TimerIslandCompactLeading() {
  return (
    <Voltra.Symbol name="timer" tintColor="#34D399" size={14} />
  )
}

/**
 * Dynamic Island - Compact Trailing (right side)
 */
export function TimerIslandCompactTrailing() {
  return (
    <Voltra.Text
      style={{
        color: '#FFFFFF',
        fontSize: 14,
        fontWeight: '600',
      }}
    >
      05:00
    </Voltra.Text>
  )
}

/**
 * Dynamic Island - Expanded Leading
 */
export function TimerIslandExpandedLeading() {
  return (
    <Voltra.VStack alignment="leading" spacing={4}>
      <Voltra.Symbol name="timer" tintColor="#34D399" size={32} />
    </Voltra.VStack>
  )
}

/**
 * Dynamic Island - Expanded Trailing
 */
export function TimerIslandExpandedTrailing() {
  return (
    <Voltra.VStack alignment="trailing" spacing={4}>
      <Voltra.Text
        style={{
          color: '#FFFFFF',
          fontSize: 32,
          fontWeight: '700',
        }}
      >
        05:00
      </Voltra.Text>
      <Voltra.Text
        style={{
          color: '#94A3B8',
          fontSize: 12,
        }}
      >
        remaining
      </Voltra.Text>
    </Voltra.VStack>
  )
}

/**
 * Dynamic Island - Expanded Bottom
 */
export function TimerIslandExpandedBottom() {
  return (
    <Voltra.HStack style={{ paddingTop: 8 }}>
      <Voltra.Button
        title="Stop"
        style={{
          backgroundColor: '#EF4444',
          borderRadius: 20,
          padding: 8,
          paddingHorizontal: 24,
        }}
        titleStyle={{
          color: '#FFFFFF',
          fontSize: 14,
          fontWeight: '600',
        }}
      />
      <Voltra.Spacer />
      <Voltra.Button
        title="Pause"
        style={{
          backgroundColor: '#3B82F6',
          borderRadius: 20,
          padding: 8,
          paddingHorizontal: 24,
        }}
        titleStyle={{
          color: '#FFFFFF',
          fontSize: 14,
          fontWeight: '600',
        }}
      />
    </Voltra.HStack>
  )
}
