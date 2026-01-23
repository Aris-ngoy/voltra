import type { WidgetVariants } from 'voltra'

import { WeatherWidget } from './WeatherWidget'

const initialState: WidgetVariants = {
  systemSmall: <WeatherWidget />,
  systemMedium: <WeatherWidget />,
  systemLarge: <WeatherWidget />,
}

export default initialState
