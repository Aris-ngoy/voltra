/**
 * Voltra Live Activity Example - Bare React Native 0.79
 * https://github.com/callstackincubator/voltra
 */

import React from 'react'
import {
  Platform,
  Pressable,
  SafeAreaView,
  StatusBar,
  StyleSheet,
  Text,
  useColorScheme,
  View,
} from 'react-native'

import { useTimerLiveActivity } from './src/components/TimerLiveActivity'

function App(): React.JSX.Element {
  const isDarkMode = useColorScheme() === 'dark'
  const { start, update, end, isActive } = useTimerLiveActivity()

  const backgroundStyle = {
    backgroundColor: isDarkMode ? '#1a1a1a' : '#f5f5f5',
    flex: 1,
  }

  const textColor = isDarkMode ? '#ffffff' : '#1a1a1a'

  if (Platform.OS !== 'ios') {
    return (
      <SafeAreaView style={[backgroundStyle, styles.container]}>
        <Text style={[styles.title, { color: textColor }]}>
          Live Activities are only supported on iOS
        </Text>
      </SafeAreaView>
    )
  }

  return (
    <SafeAreaView style={backgroundStyle}>
      <StatusBar
        barStyle={isDarkMode ? 'light-content' : 'dark-content'}
        backgroundColor={backgroundStyle.backgroundColor}
      />
      <View style={styles.container}>
        <Text style={[styles.title, { color: textColor }]}>
          🎯 Voltra Live Activity
        </Text>
        <Text style={[styles.subtitle, { color: textColor }]}>
          Timer Example
        </Text>

        <View style={styles.statusContainer}>
          <Text style={[styles.statusLabel, { color: textColor }]}>Status:</Text>
          <View
            style={[
              styles.statusBadge,
              { backgroundColor: isActive ? '#22c55e' : '#6b7280' },
            ]}
          >
            <Text style={styles.statusText}>
              {isActive ? 'Active' : 'Inactive'}
            </Text>
          </View>
        </View>

        <View style={styles.buttonContainer}>
          <Pressable
            style={[
              styles.button,
              { backgroundColor: isActive ? '#6b7280' : '#3b82f6' },
            ]}
            onPress={start}
            disabled={isActive}
          >
            <Text style={styles.buttonText}>Start</Text>
          </Pressable>

          <Pressable
            style={[
              styles.button,
              { backgroundColor: isActive ? '#f59e0b' : '#6b7280' },
            ]}
            onPress={update}
            disabled={!isActive}
          >
            <Text style={styles.buttonText}>Update</Text>
          </Pressable>

          <Pressable
            style={[
              styles.button,
              { backgroundColor: isActive ? '#ef4444' : '#6b7280' },
            ]}
            onPress={end}
            disabled={!isActive}
          >
            <Text style={styles.buttonText}>End</Text>
          </Pressable>
        </View>

        <Text style={[styles.instructions, { color: textColor }]}>
          Press "Start" to begin the Live Activity.{'\n'}
          It will appear on your Lock Screen and Dynamic Island.
        </Text>
      </View>
    </SafeAreaView>
  )
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
  },
  title: {
    fontSize: 28,
    fontWeight: '700',
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 18,
    fontWeight: '500',
    marginBottom: 32,
    opacity: 0.7,
  },
  statusContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 32,
  },
  statusLabel: {
    fontSize: 16,
    fontWeight: '500',
    marginRight: 8,
  },
  statusBadge: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
  },
  statusText: {
    color: '#ffffff',
    fontSize: 14,
    fontWeight: '600',
  },
  buttonContainer: {
    flexDirection: 'row',
    gap: 12,
    marginBottom: 32,
  },
  button: {
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 12,
    minWidth: 80,
    alignItems: 'center',
  },
  buttonText: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '600',
  },
  instructions: {
    fontSize: 14,
    textAlign: 'center',
    opacity: 0.6,
    lineHeight: 22,
  },
})

export default App

