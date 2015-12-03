var ModAPI = require('modapi')
var _ = require('lodash')
var fs = require('fs')
var path = require('path')

var readLocalFile = function(name) {
  return fs.readFileSync(path.join(__dirname, name))
}


;[
  "Main/Dialog_AboutMod.qml",
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
  aboutModMenu.object("text", 'qsTr("About") + " Mod..."')
  aboutModMenu.object("enabled", 'true')
  aboutModMenu.object("onTriggered", 'root.aboutMod()')

  var aboutModSignal = rootNode.publicMember("aboutMod")
  aboutModSignal.kind = "signal"
  aboutModSignal.statment = "()"

  qml.save()
}

var addMainAction = function() {
  var qml = ModAPI.QMLFile("Main/MainWindow.qml")
  var rootNode = qml.root.node

  var mainMenu = qml.getObjectById("mainMenu").node
  mainMenu.object("onAboutMod", "aboutModBox.open()")

  var aboutModBox = rootNode.newObject().createNode()
  aboutModBox.describe = "Dialog_AboutMod"
  aboutModBox.object("id", "aboutModBox")

  qml.save()
}

addMainMenu()
addMainAction()
