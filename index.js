var ModAPI = require('modapi')
var _ = require('lodash')
var fs = require('fs')
var path = require('path')

var readLocalFile = function(name) {
  return fs.readFileSync(path.join(__dirname, name))
}


;[
  "Main/Dialog_AboutMod.qml",
  "ModManager/Dialog_ModManager.qml",
  "ModManager/ModListBoxItem.qml",
].forEach(function(i) {
  if (path.extname(i) == ".js" && path.extname(path.basename(i, ".js")) == ".qml") {
    require("./" + i)
  } else {
    ModAPI.add(i, readLocalFile(i))
  }
})

var addMainMenu = function() {
  var qml = ModAPI.QMLFile("Main/MainMenu.qml")
  var rootNode = qml.root.node

  var rootMenus = rootNode.publicMember("menuBar").object.node.objects

  var helpMenu = _.find(rootMenus, function(i) {
    return i.node.object("title").value == 'qsTr("Help")'
  }) || _.last(rootMenus)

  var aboutModMenu = helpMenu.node.newObject().createNode()
  aboutModMenu.describe = "MenuItem"
  aboutModMenu.object("text", 'qsTr("About") + " mvUCCU..."')
  aboutModMenu.object("enabled", 'true')
  aboutModMenu.object("onTriggered", 'root.aboutMod()')

  var aboutModSignal = rootNode.publicMember("aboutMod")
  aboutModSignal.kind = "signal"
  aboutModSignal.statment = "()"

  var toolsMenu = _.find(rootMenus, function(i) {
    return i.node.object("title").value == 'qsTr("Tools")'
  }) || rootMenus[5]

  var openModManagerMenu = toolsMenu.node.newObject().createNode()
  openModManagerMenu.describe = "MenuItem"
  openModManagerMenu.object("text", '"Mod Manager..."')
  openModManagerMenu.object("enabled", 'true')
  openModManagerMenu.object("onTriggered", 'root.openModManager()')

  var openModManagerSignal = rootNode.publicMember("openModManager")
  openModManagerSignal.kind = "signal"
  openModManagerSignal.statment = "()"

  qml.save()
}

var addMainAction = function() {
  var qml = ModAPI.QMLFile("Main/MainWindow.qml")
  var rootNode = qml.root.node

  var mainMenu = qml.getObjectById("mainMenu").node
  mainMenu.object("onAboutMod", "aboutModBox.open()")
  mainMenu.object("onOpenModManager", "modManagerBox.item.open()")

  var aboutModBox = rootNode.newObject().createNode()
  aboutModBox.describe = "Dialog_AboutMod"
  aboutModBox.object("id", "aboutModBox")

  var modManagerBox = rootNode.newObject().createNode()
  modManagerBox.describe = "Loader"
  modManagerBox.object("id", "modManagerBox")
  modManagerBox.object("source", '"../ModManager/Dialog_ModManager.qml"')
  qml.save()
}

addMainMenu()
addMainAction()
