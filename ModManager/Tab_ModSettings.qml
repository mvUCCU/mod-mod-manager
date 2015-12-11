import QtQuick 2.3
import QtQuick.Controls 1.2
import Tkool.rpg 1.0
import "../BasicControls"
import "../BasicLayouts"
import "../Controls"
import "../ObjControls"
import "../Singletons"
import "../Singletons/plugin-parser"
import "../Main"

ListBox {
    id: root
    anchors.fill: parent
    anchors.margins: 8

    property var mod : null
    property var manager : null
    property var parameters: ({})

    signal modified()

    Component.onCompleted: loadScript()
    onModChanged: loadScript()

    function reset() {
        parameters = {};
    }

    wantReturn: true
    showSelectionAlways: false

    DialogBoxHelper { id: helper }

    ListBoxColumn {
        title: qsTr("Name")
        role: "name"
        width: 160
    }
    ListBoxColumn {
        title: qsTr("Value")
        role: "value"
        width: 350
    }

    model: ListModel {
        id: parameterListModel
    }

    onDoubleClicked: editParameter()
    Keys.onReturnPressed: editParameter()
    Keys.onEnterPressed: editParameter()

    Dialog_PluginParameter {
        id: parameterDialog
        onOk: finishEdit(value)
    }

    property var paramNames: []
    property var paramDescs: ({})
    property var paramDefaults: ({})

    function loadScript() {
        if (!mod) return;

        var url = TkoolAPI.pathToUrl(mod.location) + "/settings.js";
        var script = TkoolAPI.readFile(url);
        var data = PluginParser.parse(script);

        paramNames = [];
        paramDescs = {};
        paramDefaults = {};
        if (!data.parameters) data.parameters = [];
        for (var i = 0; i < data.parameters.length; i++) {
            var param = data.parameters[i];
            paramNames.push(param.name);
            paramDescs[param.name] = param.description;
            paramDefaults[param.name] = param.defaultValue;
        }
        buildParameterListModel();
    }

    function buildParameterListModel() {
        parameterListModel.clear();
        for (var i = 0; i < paramNames.length; i++) {
            var name = paramNames[i];
            var item = {};
            item.name = name;
            item.desc = paramDescs[name] || "";
            item.value = paramDefaults[name] || "";
            if (mod.settings.settings[name] !== undefined) {
                item.value = String(mod.settings.settings[name]);
            }
            parameterListModel.append(item);
        }
    }

    function editParameter() {
        var item = parameterListModel.get(currentIndex);
        if (item) {
            parameterDialog.name = item.name;
            parameterDialog.value = item.value;
            parameterDialog.description = item.desc;
            parameterDialog.open();
        }
    }

    function finishEdit(value) {
        var item = parameterListModel.get(currentIndex);
        if (item) {
            item.value = value;
            mod.settings.settings[item.name] = item.value;
            helper.setModified();
            modified();
        }
    }
}
