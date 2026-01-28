import React, { useCallback, useState } from 'react'
import { useLiveActivity } from 'voltra/client'

import {
  TimerIslandCompactLeading,
  TimerIslandCompactTrailing,
  TimerIslandExpandedBottom,
  TimerIslandExpandedLeading,
  TimerIslandExpandedTrailing,
  TimerIslandMinimal,
  TimerLockScreen,
} from './TimerLiveActivityUI'

export type TimerLiveActivityProps = {
  autoStart?: boolean
  autoUpdate?: boolean
}

export type TimerLiveActivityResult = {
  start: () => Promise<void>
  update: () => Promise<void>
  end: () => Promise<void>
  isActive: boolean
}

/**
 * Custom hook to manage the Timer Live Activity
 */
export function useTimerLiveActivity(
  props: TimerLiveActivityProps = {}
): TimerLiveActivityResult {
  const { autoStart = false, autoUpdate = true } = props

  const { start, update, end, isActive } = useLiveActivity(
    {
      lockScreen: <TimerLockScreen />,
      island: {
        keylineTint: '#34D399',
        minimal: <TimerIslandMinimal />,
        compact: {
          leading: <TimerIslandCompactLeading />,
          trailing: <TimerIslandCompactTrailing />,
        },
        expanded: {
          leading: <TimerIslandExpandedLeading />,
          trailing: <TimerIslandExpandedTrailing />,
          bottom: <TimerIslandExpandedBottom />,
        },
      },
    },
    {
      activityName: 'timer',
      autoUpdate,
      autoStart,
    }
  )

  return {
    start,
    update,
    end,
    isActive,
  }
}
