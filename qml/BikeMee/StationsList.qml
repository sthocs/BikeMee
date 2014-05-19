import QtQuick 1.1
import com.nokia.meego 1.0

Page {
    id: stationsListPage

    property bool loadingMap: false;

    function openMap(city) {
        if (loadingMap) {
            return;
        }
        loadingMap = true;
        var component = Qt.createComponent("InteractiveMap.qml")
        if (component.status == Component.Ready) {
            pageStack.push(component, { currentCity: city });
            loadingMap = false;
        }
        else {
            console.log("Error loading component:", component.errorString());
        }
    }

    Component.onCompleted: {
        cacheManager.getContracts(false);
    }

    tools: ToolBarLayout {
        id: toolbar

        ToolIcon {
            iconId: "toolbar-refresh";
            enabled: !loadingMap;
            onClicked: {
                cityModel.clear();
                welcomeText.text = "Downloading cities list...";
                cacheManager.getContracts(true);
            }
        }
        ToolIcon {
            iconId: "toolbar-view-menu";
            enabled: !loadingMap;
            onClicked: optionsMenu.open(); }
    }

    Menu {
        id: optionsMenu
        visualParent: pageStack

        MenuLayout {
            //MenuItem {text: "Clear cache"; onClicked: { cacheManager.removeCacheDir() }}
            MenuItem {text: "About"; onClicked: { aboutPopup.open() }}
        }
    }

    Connections {
        target: cacheManager
        onContractsUpdated: {
            var cities = JSON.parse(contracts);
            cities.sort(function(a, b) { return a.countryCode.charCodeAt(0) - b.countryCode.charCodeAt(0) });
            for (var i = 0; i < cities.length; ++i) {
                cityModel.append(cities[i]);
            }
        }
    }

    Text {
        id: welcomeText
        text: "Welcome!<br/>Click on Refresh to load cities list."
        font.pointSize: 30.0
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        width: parent.width
        height: parent.height
        visible: cityModel.count == 0
    }

    ListModel {
        id: cityModel
    }

    Component {
        id: sectionHeading
        Rectangle {
            width: parent.width
            height: childrenRect.height
            anchors.leftMargin: 0
            anchors.rightMargin: 0
            color: "lightsteelblue"

            Flow {
                spacing: 5
                Image {
                    source: "icons/" + section + ".png"
                    sourceSize.height: 43
                    sourceSize.width: 64
                }

                Text {
                    text: section
                    font.pixelSize: 26
                }
            }
        }
    }

    ListView {
        id: listView
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        interactive: !loadingMap

        model: cityModel

        section.property: "countryCode"
        section.criteria: ViewSection.FullString
        section.delegate: sectionHeading

        delegate:  Item {
            id: listItem
            height: 88
            width: parent.width

            BorderImage {
                id: background
                anchors.fill: parent
                // Fill page borders
                anchors.leftMargin: -stationsListPage.anchors.leftMargin
                anchors.rightMargin: -stationsListPage.anchors.rightMargin
                visible: mouseArea.pressed
                source: "image://theme/meegotouch-list-background-pressed-center"
            }

            Row {
                anchors.fill: parent

                Column {
                    anchors.verticalCenter: parent.verticalCenter

                    Label {
                        id: mainText
                        text: model.name
                        font.weight: Font.Bold
                        font.pixelSize: 26
                    }

                    Label {
                        id: subText
                        text: model.commercialName
                        font.weight: Font.Light
                        font.pixelSize: 22
                        color: "#cc6633"

                        visible: text != ""
                    }
                }
            }

            Image {
                source: "image://theme/icon-m-common-drilldown-arrow" + (theme.inverted ? "-inverse" : "")
                anchors.right: parent.right;
                anchors.verticalCenter: parent.verticalCenter
            }

            MouseArea {
                id: mouseArea
                anchors.fill: background
                onClicked: {
                    stationsListPage.openMap(name)
                }
            }
        }
    }
    ScrollDecorator {
        flickableItem: listView
    }

    AboutPopup {
        id: aboutPopup
    }
}
