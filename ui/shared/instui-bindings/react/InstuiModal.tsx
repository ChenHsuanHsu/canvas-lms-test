/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import React, {type ReactElement} from 'react'
import {CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Modal} from '@instructure/ui-modal'

const I18n = createI18nScope('modal')

/*
---
This is just a wrapper around the default instructure-ui Modal that:
 * provides a translated close button label that works with Canvas's I18n
 * sets a header title for you if you provide a `label` prop

Use this whenever you don't want to do anything custom with your header or your close button

You should be able to use it exactly like you'd use an instUi Modal by changing:
import {Modal} from '@instructure/ui-overlays'
to
import Modal from '@canvas/instui-bindings/react/InstuiModal'

<Modal
  open={this.state.open}
  onDismiss={functionToHandleModalDismissal}
  label="this will be shown as the header of the modal and read to screenreaders as the label"
>
  <form onSubmit={this.handleFormSubmit}
    <Modal.Body>
      content of the modal goes here, notice you don't need to do anything for the close button.
    </Modal.Body>
    <Modal.Footer>
      <Button onClick={functionToHandleModalDismissal}>Close</Button>&nbsp;
      <Button type="submit" variant="primary">Submit</Button>
    </Modal.Footer>
  </form>
</Modal>

---
*/

type Props = {
  label: string
  // InstUI has marked closeButtonLabel as deprecated, but we still allow it.
  // if you just want the default of `I18n.t('Close')` don't pass anything,
  // but if you want something different pass closeButtonLabel="something different"
  closeButtonLabel?: string
  onDismiss: () => void
  children: ReactElement | ReactElement[]
  [key: string]: any
}

function getLiveRegion(): HTMLElement | null {
  return document.getElementById('flash_screenreader_holder')
}

function CanvasInstUIModal({
  label,
  closeButtonLabel,
  onDismiss,
  children,
  ...otherPropsToPassOnToModal
}: Props): ReactElement {
  return (
    <Modal
      liveRegion={getLiveRegion}
      {...otherPropsToPassOnToModal}
      label={label}
      onDismiss={onDismiss}
    >
      <Modal.Header>
        <CloseButton
          data-testid="instui-modal-close"
          placement="end"
          offset="medium"
          onClick={onDismiss}
          screenReaderLabel={closeButtonLabel || I18n.t('Close')}
        />
        <Heading>{label}</Heading>
      </Modal.Header>
      {children}
    </Modal>
  )
}

export default CanvasInstUIModal

CanvasInstUIModal.Header = Modal.Header
CanvasInstUIModal.Body = Modal.Body
CanvasInstUIModal.Footer = Modal.Footer
