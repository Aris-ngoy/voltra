import React from 'react'

import { BasicLiveActivityUI } from '../../../example/components/live-activities/BasicLiveActivityUI.js'
import { MusicPlayerLiveActivityUI } from '../../../example/components/live-activities/MusicPlayerLiveActivityUI.js'
import { renderLiveActivityToString } from '../../server.js'

const getPayloadSize = async (variants: Parameters<typeof renderLiveActivityToString>[0]): Promise<number> => {
  const compressedPayload = await renderLiveActivityToString(variants)
  return compressedPayload.length
}

const sampleSong = {
  title: 'Midnight Dreams',
  artist: 'The Voltra Collective',
  image: 'voltra-icon',
}

describe('Payload size regression', () => {
  test('BasicLiveActivityUI', async () => {
    const size = await getPayloadSize({
      lockScreen: <BasicLiveActivityUI />,
    })

    expect(size).toMatchSnapshot()
  })

  test('MusicPlayerLiveActivityUI', async () => {
    const size = await getPayloadSize({
      lockScreen: <MusicPlayerLiveActivityUI currentSong={sampleSong} isPlaying={true} />,
    })

    expect(size).toMatchSnapshot()
  })
})
