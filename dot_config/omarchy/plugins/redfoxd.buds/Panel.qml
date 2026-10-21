import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Model.js" as Model

// Bar widget for Samsung Galaxy Buds: battery in the bar and a popup with the
// noise, conversation, seamless-connection, touch-lock and find controls. All
// Bluetooth work happens in bin/buds, which prints one JSON line per change
// and takes `key value` commands on stdin.
Panel {
  id: root
  moduleName: "redfoxd.buds"
  ipcTarget: "redfoxd.buds"

  // The script ships inside the plugin directory, so it works from any path.
  readonly property string script: Qt.resolvedUrl("bin/buds").toString().replace("file://", "")
  readonly property string address: {
    var value = String(setting("address", "")).trim()
    return /^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$/.test(value) ? value : ""
  }
  readonly property bool hideWhenDisconnected: setting("hideWhenDisconnected", false) === true

  readonly property color foreground: bar ? bar.foreground : Commons.Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property int holdMs: 4000

  // Last state reported by the watcher, and values the user just set that stay
  // on screen until the buds confirm them (or holdMs passes).
  property var view: Model.emptyState()
  property var pending: ({})
  property bool finding: false

  readonly property bool connected: view.connected
  readonly property string mode: Model.holdGet(pending, "mode", view.mode)
  readonly property string ancLevel: Model.holdGet(pending, "ancLevel", view.ancLevel)
  readonly property var ambientLevel: Model.holdGet(pending, "ambientLevel", view.ambientLevel)
  readonly property var detectConversations: Model.holdGet(pending, "detectConversations", view.detectConversations)
  readonly property var seamless: Model.holdGet(pending, "seamless", view.seamless)
  readonly property var touchLocked: Model.holdGet(pending, "touchLocked", view.touchLocked)
  readonly property var lowest: Model.lowestBattery(view.battery)
  readonly property string title: view.device !== "" ? view.device : strings.t("buds.title")
  readonly property string flashGlyph: "󱐋"

  readonly property var modeOptions: [
    { value: "off", label: strings.t("buds.mode.off") },
    { value: "anc", label: strings.t("buds.mode.anc") },
    { value: "ambient", label: strings.t("buds.mode.ambient") },
    { value: "adaptive", label: strings.t("buds.mode.adaptive"), tooltip: strings.t("buds.mode.experimental") }
  ]

  function batteryLabel(key) {
    var value = view.battery[key]
    if (value === null || value === undefined) return strings.t("buds.battery.unknown")
    return Model.batteryText(value)
  }

  function tooltipText() {
    if (!connected) return disconnectedMessage()
    return strings.t("buds.tooltip")
      .arg(batteryLabel("left")).arg(batteryLabel("right")).arg(batteryLabel("case"))
  }

  function disconnectedMessage() {
    if (view.error === "") return strings.t("buds.disconnected")
    return strings.t("buds.error." + view.error, strings.t("buds.disconnected"))
  }

  function send(line) {
    if (watcher.running) watcher.write(line + "\n")
  }

  // Show the new value at once, hold it until the buds agree, then send it.
  function setOption(key, value, command) {
    pending = Model.holdSet(pending, key, value)
    holdTimer.restart()
    send(command)
  }

  function setMode(value) {
    if (value !== "" && value !== mode) setOption("mode", value, "mode " + value)
  }

  function toggleFind() {
    send(finding ? "find stop" : "find start")
    finding = !finding
  }

  function applyLine(line) {
    var next = Model.parseLine(line)
    if (!next) return
    view = next
    pending = Model.holdReconcile(pending, next)
    if (!next.connected) {
      pending = ({})
      finding = false
    }
  }

  function reconnect() {
    restartTimer.interval = 300
    watcher.running = false
    restartTimer.restart()
  }

  visible: connected || !hideWhenDisconnected
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  Process {
    id: watcher
    command: [root.script, "watch"].concat(root.address !== "" ? ["--address", root.address] : [])
    running: true
    stdinEnabled: true
    stdout: SplitParser { onRead: function(line) { root.applyLine(line) } }
    onExited: {
      root.view = Model.emptyState()
      root.pending = ({})
      root.finding = false
      restartTimer.start()
    }
  }

  Timer {
    id: restartTimer
    interval: 2000
    onTriggered: {
      interval = 2000
      watcher.running = true
    }
  }

  Timer {
    id: holdTimer
    interval: root.holdMs
    onTriggered: root.pending = ({})
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰋋"
    tooltipText: root.tooltipText()
    dimmed: !root.connected
    useActiveColor: false
    onPressed: function(code) {
      if (code === Qt.RightButton) {
        if (root.connected) root.setMode(Model.nextMode(root.mode))
      } else {
        root.toggle()
      }
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: panel.loadedContent
    contentWidth: panel.fittedContentWidth(Style.space(400))
    contentHeight: panel.fittedContentHeight(panel.loadedContentHeight, Style.space(560))

    content: PanelKeyCatcher {
      anchors.fill: parent
      implicitHeight: column.implicitHeight
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        width: parent.width
        spacing: Style.space(12)

        Text {
          width: parent.width
          text: root.title
          textFormat: Text.PlainText
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.heading
          font.bold: true
          elide: Text.ElideRight
        }

        // Disconnected: say why, offer a reconnect.
        Column {
          width: parent.width
          spacing: Style.space(8)
          visible: !root.connected

          Text {
            width: parent.width
            text: root.disconnectedMessage()
            textFormat: Text.PlainText
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            wrapMode: Text.WordWrap
          }

          Text {
            width: parent.width
            text: strings.t("buds.disconnected.hint")
            textFormat: Text.PlainText
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WordWrap
          }

          Button {
            text: strings.t("buds.connect")
            bordered: true
            foreground: root.foreground
            fontFamily: root.fontFamily
            onClicked: root.reconnect()
          }
        }

        Column {
          width: parent.width
          spacing: Style.space(12)
          visible: root.connected

          Row {
            id: batteryRow
            width: parent.width
            spacing: Style.space(18)

            Repeater {
              model: [
                { label: strings.t("buds.battery.left"), key: "left" },
                { label: strings.t("buds.battery.right"), key: "right" },
                { label: strings.t("buds.battery.case"), key: "case" }
              ]

              delegate: Column {
                required property var modelData
                width: (batteryRow.width - batteryRow.spacing * 2) / 3
                spacing: Style.space(2)

                Text {
                  text: modelData.label
                  textFormat: Text.PlainText
                  color: root.dim
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                }

                Row {
                  spacing: Style.space(4)

                  Text {
                    text: root.batteryLabel(modelData.key)
                    textFormat: Text.PlainText
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                  }

                  Text {
                    visible: root.view.charging[modelData.key] === true
                    text: root.flashGlyph
                    textFormat: Text.PlainText
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                  }
                }
              }
            }
          }

          PanelSeparator { foreground: root.foreground }

          PanelSectionHeader {
            width: parent.width
            text: strings.t("buds.noise")
            foreground: root.foreground
            fontFamily: root.fontFamily
          }

          ButtonGroup {
            options: root.modeOptions
            value: root.mode
            focusable: false
            foreground: root.foreground
            fontFamily: root.fontFamily
            onChanged: function(value) { root.setMode(value) }
          }

          Text {
            width: parent.width
            text: strings.t("buds.mode.experimental")
            textFormat: Text.PlainText
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }

          ToggleRow {
            visible: root.mode === "anc"
            label: strings.t("buds.ancLevel")
            checked: root.ancLevel === "high"
            onToggled: {
              var next = root.ancLevel === "high" ? "low" : "high"
              root.setOption("ancLevel", next, "anc_level " + next)
            }
          }

          Column {
            width: parent.width
            spacing: Style.space(4)
            visible: root.mode === "ambient"

            Text {
              width: parent.width
              text: strings.t("buds.ambientLevel")
              textFormat: Text.PlainText
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
            }

            PanelSlider {
              width: parent.width
              bar: root.bar
              minimum: 0
              maximum: 2
              step: 1
              integer: true
              tickCount: 3
              value: root.ambientLevel === null ? 0 : root.ambientLevel
              onReleased: function(next) {
                var level = Math.round(next)
                if (level !== root.ambientLevel)
                  root.setOption("ambientLevel", level, "ambient_level " + level)
              }
            }
          }

          PanelSeparator { foreground: root.foreground }

          PanelSectionHeader {
            width: parent.width
            text: strings.t("buds.controls")
            foreground: root.foreground
            fontFamily: root.fontFamily
          }

          ToggleRow {
            label: strings.t("buds.conversations")
            checked: root.detectConversations === true
            onToggled: {
              var on = root.detectConversations !== true
              root.setOption("detectConversations", on, "conversation " + (on ? "on" : "off"))
            }
          }

          ToggleRow {
            label: strings.t("buds.seamless")
            hint: strings.t("buds.seamless.hint")
            checked: root.seamless === true
            onToggled: {
              var on = root.seamless !== true
              root.setOption("seamless", on, "seamless " + (on ? "on" : "off"))
            }
          }

          ToggleRow {
            label: strings.t("buds.touchLock")
            checked: root.touchLocked === true
            onToggled: {
              var on = root.touchLocked !== true
              root.setOption("touchLocked", on, "touch_lock " + (on ? "on" : "off"))
            }
          }

          PanelSeparator { foreground: root.foreground }

          Column {
            width: parent.width
            spacing: Style.space(6)

            Text {
              width: parent.width
              text: strings.t("buds.find.hint")
              textFormat: Text.PlainText
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }

            Button {
              text: root.finding ? strings.t("buds.find.stop") : strings.t("buds.find.start")
              bordered: true
              selected: root.finding
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: root.toggleFind()
            }
          }
        }
      }
    }
  }

  // Label on the left, switch on the right, optional hint below the label.
  component ToggleRow: Item {
    id: row

    property string label: ""
    property string hint: ""
    property bool checked: false
    signal toggled()

    width: parent ? parent.width : 0
    implicitHeight: Math.max(texts.implicitHeight, toggle.implicitHeight)

    Column {
      id: texts
      anchors.left: parent.left
      anchors.right: toggle.left
      anchors.rightMargin: Style.spacing.lg
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(2)

      Text {
        width: parent.width
        text: row.label
        textFormat: Text.PlainText
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        wrapMode: Text.WordWrap
      }

      Text {
        visible: row.hint !== ""
        width: parent.width
        text: row.hint
        textFormat: Text.PlainText
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
      }
    }

    ToggleSwitch {
      id: toggle
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      checked: row.checked
      foreground: root.foreground
      onToggled: row.toggled()
    }
  }
}
