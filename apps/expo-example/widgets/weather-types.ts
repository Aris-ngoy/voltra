export type WeatherCondition =
  | 'sunny'
  | 'partly-cloudy'
  | 'cloudy'
  | 'rainy'
  | 'stormy'
  | 'snowy'
  | 'foggy'
  | 'windy'
  | 'hot'
  | 'cold'

export interface WeatherData {
  condition: WeatherCondition
  temperature: number
  highTemp?: number
  lowTemp?: number
  location?: string
  description?: string
  humidity?: number
  windSpeed?: number
  lastUpdated?: Date
}

export const WEATHER_GRADIENTS: Record<
  WeatherCondition,
  { colors: readonly [string, string, ...string[]]; start?: string; end?: string }
> = {
  sunny: {
    colors: ['#FFD700', '#FFA500', '#FF8C00'], // Gold to orange gradient
    start: 'top',
    end: 'bottom',
  },
  'partly-cloudy': {
    colors: ['#87CEEB', '#F0F8FF', '#B0E0E6'], // Sky blue to light blue
    start: 'top',
    end: 'bottom',
  },
  cloudy: {
    colors: ['#778899', '#B0C4DE', '#D3D3D3'], // Gray tones
    start: 'top',
    end: 'bottom',
  },
  rainy: {
    colors: ['#4682B4', '#5F9EA0', '#778899'], // Steel blue to cadet blue
    start: 'top',
    end: 'bottom',
  },
  stormy: {
    colors: ['#2F4F4F', '#696969', '#A9A9A9'], // Dark slate to dim gray
    start: 'top',
    end: 'bottom',
  },
  snowy: {
    colors: ['#F0F8FF', '#E6E6FA', '#B0C4DE'], // Alice blue to light steel blue
    start: 'top',
    end: 'bottom',
  },
  foggy: {
    colors: ['#F5F5F5', '#D3D3D3', '#A9A9A9'], // White smoke to light gray
    start: 'top',
    end: 'bottom',
  },
  windy: {
    colors: ['#87CEEB', '#98FB98', '#F0F8FF'], // Sky blue with mint accent
    start: 'top',
    end: 'bottom',
  },
  hot: {
    colors: ['#FF4500', '#FF6347', '#FFD700'], // Red orange to gold
    start: 'top',
    end: 'bottom',
  },
  cold: {
    colors: ['#4169E1', '#000080', '#191970'], // Royal blue to midnight blue
    start: 'top',
    end: 'bottom',
  },
}

export const WEATHER_EMOJIS: Record<WeatherCondition, string> = {
  sunny: '☀️',
  'partly-cloudy': '⛅',
  cloudy: '☁️',
  rainy: '🌧️',
  stormy: '⛈️',
  snowy: '❄️',
  foggy: '🌫️',
  windy: '💨',
  hot: '🔥',
  cold: '🥶',
}

export const WEATHER_DESCRIPTIONS: Record<WeatherCondition, string> = {
  sunny: 'Sunny',
  'partly-cloudy': 'Partly Cloudy',
  cloudy: 'Cloudy',
  rainy: 'Rainy',
  stormy: 'Stormy',
  snowy: 'Snowy',
  foggy: 'Foggy',
  windy: 'Windy',
  hot: 'Hot',
  cold: 'Cold',
}

// Sample weather data for testing
export const SAMPLE_WEATHER_DATA: Record<WeatherCondition, WeatherData> = {
  sunny: {
    condition: 'sunny',
    temperature: 75,
    highTemp: 82,
    lowTemp: 68,
    location: 'San Francisco',
    description: 'Clear skies',
    humidity: 65,
    windSpeed: 8,
    lastUpdated: new Date(),
  },
  'partly-cloudy': {
    condition: 'partly-cloudy',
    temperature: 72,
    highTemp: 78,
    lowTemp: 65,
    location: 'New York',
    description: 'Partly cloudy',
    humidity: 70,
    windSpeed: 12,
    lastUpdated: new Date(),
  },
  cloudy: {
    condition: 'cloudy',
    temperature: 68,
    highTemp: 74,
    lowTemp: 62,
    location: 'London',
    description: 'Overcast',
    humidity: 85,
    windSpeed: 6,
    lastUpdated: new Date(),
  },
  rainy: {
    condition: 'rainy',
    temperature: 62,
    highTemp: 68,
    lowTemp: 58,
    location: 'Seattle',
    description: 'Light rain',
    humidity: 92,
    windSpeed: 15,
    lastUpdated: new Date(),
  },
  stormy: {
    condition: 'stormy',
    temperature: 58,
    highTemp: 64,
    lowTemp: 54,
    location: 'Miami',
    description: 'Thunderstorms',
    humidity: 88,
    windSpeed: 25,
    lastUpdated: new Date(),
  },
  snowy: {
    condition: 'snowy',
    temperature: 28,
    highTemp: 32,
    lowTemp: 24,
    location: 'Denver',
    description: 'Snow showers',
    humidity: 75,
    windSpeed: 10,
    lastUpdated: new Date(),
  },
  foggy: {
    condition: 'foggy',
    temperature: 55,
    highTemp: 60,
    lowTemp: 52,
    location: 'San Francisco',
    description: 'Foggy',
    humidity: 95,
    windSpeed: 3,
    lastUpdated: new Date(),
  },
  windy: {
    condition: 'windy',
    temperature: 64,
    highTemp: 70,
    lowTemp: 58,
    location: 'Chicago',
    description: 'Windy',
    humidity: 55,
    windSpeed: 28,
    lastUpdated: new Date(),
  },
  hot: {
    condition: 'hot',
    temperature: 95,
    highTemp: 102,
    lowTemp: 88,
    location: 'Phoenix',
    description: 'Very hot',
    humidity: 15,
    windSpeed: 8,
    lastUpdated: new Date(),
  },
  cold: {
    condition: 'cold',
    temperature: 15,
    highTemp: 18,
    lowTemp: 10,
    location: 'Anchorage',
    description: 'Freezing cold',
    humidity: 80,
    windSpeed: 12,
    lastUpdated: new Date(),
  },
}

export const DEFAULT_WEATHER: WeatherData = {
  condition: 'sunny',
  temperature: 72,
  highTemp: 78,
  lowTemp: 65,
  location: 'San Francisco',
  lastUpdated: new Date(),
}
