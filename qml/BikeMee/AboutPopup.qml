// import QtQuick 1.0 // to target S60 5th Edition or Maemo 5
import QtQuick 1.1
import com.nokia.meego 1.0

Dialog {
    id: aboutPopup
    width: parent.width - 42
    height: parent.height
    anchors.margins: 30
    y: 42

    title: Flow {
        id: title
        width: parent.width
        anchors.margins: 10

        Text {
            id: titleField
            font.pixelSize: 22
            color: "white"
            text: "About "
        }
        Text { text: " B"; color: "#FEBA02"; font.pixelSize: 42 }
        Text { text: "i"; color: "#028CBB"; font.pixelSize: 42 }
        Text { text: "k"; color: "#ea2c81"; font.pixelSize: 42 }
        Text { text: "e"; color: "#c0bc01"; font.pixelSize: 42 }
        Text { text: "M"; color: "#76a1d6"; font.pixelSize: 42 }
        Text { text: "ee"; color: "#c491c5"; font.pixelSize: 42 }
    }

    content: Flickable {
        id: content
        height: Math.min(stationsListPage.height - title.height - okButton.height - 42, about.height + 42)
        width: parent.width
        contentHeight: about.height
        clip: true

        Text {
            id: about
            font.pixelSize:15
            width: parent.width
            wrapMode: Text.WordWrap
            anchors.centerIn: parent
            anchors.margins: 10
            color: "white"
            style: Text.Sunken
            onLinkActivated: Qt.openUrlExternally("http://www.cyclocity.com")
            text: "Find a bike in your city! This app helps you to find a bike or a free parking spot for the self-service bicycle scheme " +
                  "provided by JCDecaux: <a href=\"http://en.cyclocity.com\">CyclOcity</a><br/>" +
                  "It provides a simple interactive map displaying all CyclOcity stations by city, their number of " +
                  "available bikes and free parking spots, and the geolocation." +
                  ' Click on <img src="icons/radar.png" width="24" height="24"/> to activate the geolocation and on ' +
                  '<img src="icons/center_position.png" width="24" height="24"/> to center the map on your position.<br/><br/>' +
                  "*************************<br/><br/>" +
                  "Trouvez rapidement un vélo ou une place disponible dans votre ville!<br/>" +
                  "BikeMee fourni les outils indispensables pour se servir de <a href=\"http://www.cyclocity.com\">CyclOcity</a>, " +
                  "le système de vélos en libre-service mis en place par JCDecaux : la carte interactive des stations de chaque ville " +
                  ' et la géolocalisation. Cliquez sur <img src="icons/radar.png" width="24" height="24"/> pour activer la géolocalisation et sur ' +
                  '<img src="icons/center_position.png" width="24" height="24"/> pour recenter la map sur votre position.'
        }
    }

    buttons: ButtonRow {
        id: okButton
        style: ButtonStyle { }
        anchors.horizontalCenter: parent.horizontalCenter
        Button { text: "OK"; onClicked: { aboutPopup.accept();}}
    }
}
