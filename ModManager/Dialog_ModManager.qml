import QtQuick 2.3
import QtQuick.Controls 1.2
import QtQuick.Layouts 1.1
import Tkool.rpg 1.0
import "../BasicControls"
import "../BasicLayouts"
import "../Singletons"
import "."

ModalWindow {
    id: root

    title: qsTr("Mod Manager")

    DialogBox {
        id: dialogBox

        okVisible: true
        cancelVisible: true
        applyVisible: true

        property var modsData: null
        property var settingsPath: null

        onInit: {
            loadModsData();

            modList.setData(modsData.mods);
            modList.currentIndex = 0;

            applyEnabled = true;
        }

        onOk: {
            saveModSettings();
        }

        onApply: {
            saveModSettings();
            applyEnabled = true;
        }

        Palette { id: pal }
        DialogBoxHelper { id: helper } // helper.setModified();

        function buildModSettingsUrl(name) {
            return settingsPath + encodeURIComponent(name) + ".json";
        }

        function loadModSetting(name) {
            var settings = { enabled: true, settings: {} };
            var path = buildModSettingsUrl(name);
            try {
                var json = TkoolAPI.readFile(path);
                if (json) {
                    var data = JSON.parse(json);
                    if ( (typeof data === 'function') || (typeof data === 'object')) {
                        settings = data;
                        settings.enabled = !!settings.enabled;
                    }
                }
            } catch (e) {
                console.warn(e);
            }
            return settings;
        }

        function saveModSettings() {
            for (var i = 0; i < modsData.mods.length; i++) {
                saveModSetting(modsData.mods[i].name, modsData.mods[i].settings);
            }
        }

        function saveModSetting(name, settings) {
            var path = buildModSettingsUrl(name);
            try {
                TkoolAPI.writeFile(path, JSON.stringify(settings));
            } catch (e) {
                console.error(e);
            }
        }

        function findDependent(mod) {
            var result = [];

            for (var i = 0; i < modsData.mods.length; i++) {
                var dependencies = {};
                if (modsData.mods[i].manifest && modsData.mods[i].manifest.dependencies)
                    dependencies = modsData.mods[i].manifest.dependencies;

                if (dependencies[mod.name])
                    result.push(modsData.mods[i]);
            }

            return result;
        }

        function findDependency(mod) {
            var result = [];
            var dependencies = {};

            if (mod.manifest && mod.manifest.dependencies)
                dependencies = mod.manifest.dependencies;

            for (var i = 0; i < modsData.mods.length; i++) {
                if (dependencies[modsData.mods[i].name])
                    result.push(modsData.mods[i]);
            }

            return result;
        }

        function setModStatus(i, status) {
            var mod = modsData.mods[i];
            if (mod.settings.enabled == status) return;

            var dependencies = [];
            if (status)
                dependencies = findDependency(mod);
            else
                dependencies = findDependent(mod);

            if (dependencies.length > 0) {
                for (var i = 0; i < dependencies.length; i++) {
                    dependencies[i].settings.enabled = status;
                }
            }
            mod.settings.enabled = status;
            modList.refresh();
        }

        function loadModsData() {
            modsData = loadRawModsData();

            settingsPath = TkoolAPI.pathToUrl(modsData.path) + "/.settings/"
            if (!TkoolAPI.isDirectoryExists(settingsPath)) {
                TkoolAPI.createDirectories(settingsPath);
            }

            for (var i = 0; i < modsData.mods.length; i++) {
                modsData.mods[i].settings = loadModSetting(modsData.mods[i].name);
                saveModSetting(modsData.mods[i].name, modsData.mods[i].settings);
            }
        }

        function loadRawModsData() {
          var path = ":/qml/ModManager/mods.json";
          try {
              var json = TkoolAPI.readResource(path);
              if (json) {
                  return JSON.parse(json);
              } else {
                  return null;
              }
          } catch (e) {
              console.warn(e);
              return null;
          }
        }

        DialogBoxColumn {
            DialogBoxRow {
                ListBox {
                    id: modList
                    width: 200
                    height: 360

                    itemHeight: 48

                    headerVisible: false
                    multiSelect: false
                    showSelectionAlways: true
                    wantReturn: false

                    itemDelegate: ModListBoxItem { }

                    contextMenu: Menu {
                        id: contextMenu

                        MenuItem {
                            text: qsTr("Turn ON")
                            onTriggered: {
                                modList.changeSelectedItemStatuses(true);
                            }
                        }
                        MenuItem {
                            text: qsTr("Turn OFF")
                            onTriggered: {
                                modList.changeSelectedItemStatuses(false);
                            }
                        }
                    }

                    model: ListModel {
                        id: listModel
                    }

                    property var data: null

                    function changeSelectedItemStatuses(status) {
                        for (var i = 0; i < data.length; i++) {
                            if (isSelected(i)) {
                                dialogBox.setModStatus(i, status);
                            }
                        }
                    }

                    function refresh() {
                        for (var i = 0; i < data.length; i++) {
                            listModel.set(i, makeModelItem(data[i]));
                        }
                    }

                    function setData(_data) {
                        data = _data;
                        build();
                    }

                    function build() {
                        listModel.clear();
                        for (var i = 0; i < data.length; i++) {
                            listModel.append(makeModelItem(data[i]));
                        }
                    }

                    ListBoxColumn {
                        role: "name"
                    }

                    function makeModelItem(data) {
                        return {
                            name: data.name,
                            version: data.manifest.version,
                            loaded: data.loaded,
                            enabled: data.settings.enabled,
                            description: data.manifest.description
                        }
                    }

                    onCurrentIndexChanged: { ; }
                }
                TextArea {
                    id: textArea
                    readOnly: true
                    selectAllOnFocus: false
                    width: 560
                    height: 360
                    font.pixelSize: pal.labelFontSize * 0.9
                }
            }
        }
    }
}