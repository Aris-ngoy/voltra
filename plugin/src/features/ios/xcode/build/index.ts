import { XcodeProject } from '@expo/config-plugins'

import type { WidgetFiles } from '../../../../types'
import { addXCConfigurationList } from './configurationList'
import { addBuildPhases } from './phases'

export interface ConfigureBuildOptions {
  targetName: string
  targetUuid: string
  bundleIdentifier: string
  deploymentTarget: string
  currentProjectVersion: string
  marketingVersion?: string
  groupName: string
  productFile: {
    uuid: string
    target: string
    basename: string
    group: string
  }
  widgetFiles: WidgetFiles
  codeSignStyle?: string
  developmentTeam?: string
  provisioningProfileSpecifier?: string
}

/**
 * Configures the build settings and phases for the widget extension.
 *
 * This:
 * - Creates the XCConfigurationList with Debug/Release configurations
 * - Adds all required build phases (Sources, CopyFiles, Frameworks, Resources)
 */
export function configureBuild(xcodeProject: XcodeProject, options: ConfigureBuildOptions) {
  const {
    targetName,
    targetUuid,
    bundleIdentifier,
    deploymentTarget,
    currentProjectVersion,
    marketingVersion,
    groupName,
    productFile,
    widgetFiles,
    codeSignStyle,
    developmentTeam,
    provisioningProfileSpecifier,
  } = options

  const xCConfigurationList = addXCConfigurationList(xcodeProject, {
    targetName,
    currentProjectVersion,
    bundleIdentifier,
    deploymentTarget,
    marketingVersion,
    codeSignStyle,
    developmentTeam,
    provisioningProfileSpecifier,
  })

  addBuildPhases(xcodeProject, {
    targetUuid,
    groupName,
    productFile,
    widgetFiles,
  })

  return xCConfigurationList
}
