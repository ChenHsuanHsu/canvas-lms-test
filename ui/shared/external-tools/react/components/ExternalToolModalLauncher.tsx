/*
 * Copyright (C) 2016 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */


// TODO: if editing this file, please consider removing/resolving some of the "any" references

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import iframeAllowances from '@canvas/external-apps/iframeAllowances'
import CanvasModal from '@canvas/instui-bindings/react/Modal'
import ToolLaunchIframe from './ToolLaunchIframe'
import {handleExternalContentMessages} from '../../messages'

const I18n = createI18nScope('external_toolsModalLauncher')

type ExternalToolModalLauncherState = {
  modalLaunchStyle: {
    border: string,
    width?: number,
    height?: number,
  },
  beforeExternalContentAlertClass?: string,
  afterExternalContentAlertClass?: string,
}

export type ExternalToolModalLauncherProps = {
  appElement: Element,
  title: string,
  tool: {
    definition_id: string,
    placements?: Record<string, {
      selection_width?: number,
      selection_height?: number,
      launch_width?: number,
      launch_height?: number,
    }>
  },
  isOpen: boolean,
  onRequestClose: () => void,
  contextType: string,
  contextId: number | string,
  launchType: string,
  contextModuleId?: string,
  onExternalContentReady?: (data: any) => void,
  onDeepLinkingResponse?: (data: any) => void,
  resourceSelection?: boolean,
}

export default class ExternalToolModalLauncher extends React.Component<ExternalToolModalLauncherProps> {
  removeExternalContentListener?: () => void
  iframe?: HTMLIFrameElement | null
  beforeAlert?: HTMLDivElement | null
  afterAlert?: HTMLDivElement | null

  static defaultProps = {
    appElement: document.getElementById('application'),
  }

  state: ExternalToolModalLauncherState = {
    beforeExternalContentAlertClass: 'screenreader-only',
    afterExternalContentAlertClass: 'screenreader-only',
    modalLaunchStyle: {border: 'none'},
  }

  componentDidMount() {
    this.removeExternalContentListener = handleExternalContentMessages({
      ready: this.onExternalToolCompleted,
      cancel: () => this.onExternalToolCompleted({}),
      onDeepLinkingResponse: this.props.onDeepLinkingResponse,
    })
  }

  componentWillUnmount() {
    this.removeExternalContentListener?.()
  }

  onExternalToolCompleted = (data: any) => {
    if (this.props.onExternalContentReady) {
      this.props.onExternalContentReady(data)
    }
    this.props.onRequestClose()
  }

  getIframeSrc = () => {
    if (this.props.isOpen && this.props.tool) {
      return [
        '/',
        this.props.contextType,
        's/',
        this.props.contextId,
        '/external_tools/',
        this.props.tool.definition_id,
        this.props.resourceSelection ? '/resource_selection' : '',
        '?display=borderless&launch_type=',
        this.props.launchType,
        this.props.contextModuleId && '&context_module_id=',
        this.props.contextModuleId,
      ].join('')
    }
  }

  getLaunchDimensions = () => {
    const dimensions = {
      width: 700,
      height: 700,
    }

    if (
      this.props.isOpen &&
      this.props.tool &&
      this.props.launchType &&
      this.props.tool.placements &&
      this.props.tool.placements[this.props.launchType]
    ) {
      const placement = this.props.tool.placements[this.props.launchType]
      dimensions.width = placement.launch_width || placement.selection_width || dimensions.width
      dimensions.height = placement.launch_height || placement.selection_height || dimensions.height
    }

    return dimensions
  }

  handleAlertBlur = (event: React.FocusEvent<HTMLDivElement>) => {
    const newState: ExternalToolModalLauncherState = {
      modalLaunchStyle: {
        border: 'none',
      },
    }
    if (event.target.className.search('before') > -1) {
      newState.beforeExternalContentAlertClass = 'screenreader-only'
    } else if (event.target.className.search('after') > -1) {
      newState.afterExternalContentAlertClass = 'screenreader-only'
    }
    this.setState(newState)
  }

  handleAlertFocus = (event: React.FocusEvent<HTMLDivElement>) => {
    const newState: ExternalToolModalLauncherState = {
      modalLaunchStyle: {
        width: this.iframe!.offsetWidth - 4,
        border: '2px solid #2B7ABC',
      },
    }
    if (event.target.className.search('before') > -1) {
      newState.beforeExternalContentAlertClass = ''
    } else if (event.target.className.search('after') > -1) {
      newState.afterExternalContentAlertClass = ''
    }
    this.setState(newState)
  }

  onAfterOpen = () => {
    if (this.iframe) {
      this.iframe.setAttribute('allow', iframeAllowances())
    }
  }

  render() {
    const beforeAlertStyles = `before_external_content_info_alert ${this.state.beforeExternalContentAlertClass}`
    const afterAlertStyles = `after_external_content_info_alert ${this.state.afterExternalContentAlertClass}`

    const modalLaunchStyle = {
      ...this.getLaunchDimensions(),
      ...this.state.modalLaunchStyle
    }

    return (
      <CanvasModal
        label={I18n.t('%{externalToolText}', {externalToolText: this.props.title || 'Launch External Tool'})}
        open={this.props.isOpen}
        onDismiss={this.props.onRequestClose}
        onOpen={this.onAfterOpen}
        title={this.props.title}
        appElement={this.props.appElement}
        shouldCloseOnDocumentClick={false}
        footer={null}
      >
        <div
          onFocus={this.handleAlertFocus}
          onBlur={this.handleAlertBlur}
          className={beforeAlertStyles}
          ref={e => {
            this.beforeAlert = e
          }}
        >
          <div className="ic-flash-info">
            <div className="ic-flash__icon" aria-hidden="true">
              <i className="icon-info" />
            </div>
            {I18n.t('The following content is partner provided')}
          </div>
        </div>
        <ToolLaunchIframe
          src={this.getIframeSrc()}
          style={modalLaunchStyle}
          title={this.props.title}
          ref={e => {
            this.iframe = e
          }}
        />
        <div
          onFocus={this.handleAlertFocus}
          onBlur={this.handleAlertBlur}
          className={afterAlertStyles}
          ref={e => {
            this.afterAlert = e
          }}
        >
          <div className="ic-flash-info">
            <div className="ic-flash__icon" aria-hidden="true">
              <i className="icon-info" />
            </div>
            {I18n.t('The preceding content is partner provided')}
          </div>
        </div>
      </CanvasModal>
    )
  }
}
