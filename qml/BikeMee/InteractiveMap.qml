import QtQuick 1.1
import com.nokia.meego 1.0
import QtMobility.location 1.2
import "inneractive"


Page {
    id: interactiveMap
    width: parent.width
    height: parent.height

    property bool mapLoaded: false
    // Indicates if the user has requested to display his position
    property bool findMe: false
    property bool positionReceived: false
    property Coordinate currentCoord: Coordinate { latitude: 0; longitude: 0 }
    property string currentCity: "Paris"
    property string selectedStationName: ""


    //! Used to indicate if device is in portrait mode
    property bool isPortrait: (screen.currentOrientation === Screen.Landscape) ? false : true

    //! We stop retrieving position information when component is to be destroyed
    Component.onDestruction: positionSource.stop();

    //! Check if application is active, stop position updates if not
    Connections {
        target: Qt.application
        onActiveChanged: {
            if (Qt.application.active) {
                if (findMe) {
                    positionSource.start();
                }
            }
            else {
                positionSource.stop();
            }
        }
    }

    onIsPortraitChanged: {
        if (mapLoaded) {
            printStations()
        }
    }

    Coordinate { id: mapCenter; latitude: 48.856047; longitude: 2.353907 }

    //! Container for map element
    Rectangle {
        id : mapview
        height: parent.height
        width: parent.width

        //! Map element centered with current position
        Map {
            id: map
            z: 1
            plugin : Plugin {
                        name : "nokia";

                        //! Location requires usage of app_id and token parameters.
                        //! Values below are for testing purposes only, please obtain real values.
                        //! Go to https://api.developer.nokia.com/ovi-api/ui/registration?action=list.
                        parameters: [
                            PluginParameter { name: "app_id"; value: "changeme" },
                            PluginParameter { name: "token"; value: "changeme" }
                       ]
                    }
            anchors.fill: parent
            size { width: parent.width; height: parent.height }
            center: mapCenter // Paris, Hotel de Ville by default. Updated after stations loading.

            mapType: Map.StreetMap
            zoomLevel: 16

            Component.onCompleted: {
                mapLoaded = true;
                cacheManager.downloadCarto(currentCity);
            }

            //! Icon to display the current position
            MapImage {
                id: mapPlacer
                source: "icons/me.png"
                coordinate: positionSource.position.coordinate
                offset.x: -24
                offset.y: -24
            }
        }

        //! Panning and pinch implementation on the maps
        PinchArea {
            id: pincharea

            //! Holds previous zoom level value
            property double __oldZoom

            anchors.fill: parent

            //! Calculate zoom level
            function calcZoomDelta(zoom, percent) {
                return zoom + Math.log(percent)/Math.log(2)
            }

            //! Save previous zoom level when pinch gesture started
            onPinchStarted: {
                __oldZoom = map.zoomLevel
            }

            //! Update map's zoom level when pinch is updating
            onPinchUpdated: {
                map.zoomLevel = calcZoomDelta(__oldZoom, pinch.scale)
            }

            //! Update map's zoom level when pinch is finished
            onPinchFinished: {
                map.zoomLevel = Math.max(calcZoomDelta(__oldZoom, pinch.scale), 15) // 15 min, otherwise too much points to display
                printStations();
            }
        }

        //! Map's mouse area for implementation of panning in the map and zoom on double click
        MouseArea {
            id: mousearea

            //! Property used to indicate if panning the map
            property bool __isPanning: false

            //! Last pressed X and Y position
            property int __lastX: -1
            property int __lastY: -1

            anchors.fill : parent

            //! When pressed, indicate that panning has been started and update saved X and Y values
            onPressed: {
                __isPanning = true
                __lastX = mouse.x
                __lastY = mouse.y
            }

            //! When released, indicate that panning has finished
            onReleased: {
                __isPanning = false
                if (map.zoomLevel < 15) { // If we try to move while pinching out, can stay blocked.
                    map.zoomLevel = 15;
                }

                printStations();
            }

            //! Move the map when panning
            onPositionChanged: {
                if (__isPanning) {
                    var dx = mouse.x - __lastX
                    var dy = mouse.y - __lastY
                    map.pan(-dx, -dy)
                    __lastX = mouse.x
                    __lastY = mouse.y
                }
            }

            //! When canceled, indicate that panning has finished
            onCanceled: {
                __isPanning = false;
            }

            //! Zoom one level when double clicked
            onDoubleClicked: {
                map.center = map.toCoordinate(Qt.point(__lastX,__lastY))
                map.zoomLevel += 1
            }
        }
    }

    Connections {
        target: cacheManager
        onCartoChanged: {
            printStations(true);
            stationLoadingLabel.visible = false;
        }

        onGotStationDetails: {
            station.clear();
            station.append(JSON.parse(stationDetails));
        }
    }

    ListModel {
        id: stations
    }

    ListModel {
        id: station
    }

    Repeater {
        onItemAdded: {
            map.addMapObject(item)
        }
        onItemRemoved: {
            map.removeMapObject(item)
        }
        model: stations
        delegate: MapImage {
            coordinate: Coordinate {
                latitude: model.latitude;
                longitude: model.longitude;
            }
            source: (name !== selectedStationName) ? "icons/velib_pin.png" : "icons/velib_selected.png"

            /*!
             * We want that bottom middle edge of icon points to the location, so using offset parameter
             * to change the on-screen position from coordinate. Values are calculated based on icon size,
             * in our case icon is 64x64
             */
            offset.x: -32
            offset.y: -64

            MapMouseArea {
                anchors.fill: parent
                onClicked: {
                    updatingLabel.visible = true
                    selectedStationName = name
                    //console.log('CLICKED ' + name + " " + number + " name: " + name)
                    cacheManager.getStationDetails(number);
                }
            }
        }
    }

    function printStations(centerMap) {
        stations.clear();
        //var start = new Date();

        //TODO keep it in a JS var (does not work in QML, very slow).
        var stationsArray = JSON.parse(cacheManager.cartoJson);
        if (centerMap) {
            var avgLat = 0;
            var avgLng = 0;
            var nbTestStations = 0;
            for (var i = 0; i < stationsArray.length; ++i) {
                avgLat += stationsArray[i].latitude;
                avgLng += stationsArray[i].longitude;
                if (stationsArray[i].latitude === 0) {
                    ++nbTestStations;
                }
            }
            avgLat /= (stationsArray.length - nbTestStations);
            avgLng /= (stationsArray.length - nbTestStations);
            mapCenter.latitude = avgLat;
            mapCenter.longitude = avgLng;
        }
//        var now = new Date();
//        console.log('Elapsed time: ' + (now.getTime() - start.getTime()));

        var topLeft = map.toCoordinate(Qt.point(0, 0));
        var bottomRight = map.toCoordinate(Qt.point(map.width, map.height));
        for (var i = 0; i < stationsArray.length; ++i) {
//            if (stationsArray[i].position.lat < topLeft.latitude && stationsArray[i].position.lat > bottomRight.latitude &&
//                stationsArray[i].position.lng > topLeft.longitude && stationsArray[i].position.lng < bottomRight.longitude) {
//                stations.append(stationsArray[i]);
//                console.log("append: " + stationsArray[i].number);
//            }
            if (stationsArray[i].latitude < topLeft.latitude && stationsArray[i].latitude > bottomRight.latitude &&
                stationsArray[i].longitude > topLeft.longitude && stationsArray[i].longitude < bottomRight.longitude) {
                stations.append(stationsArray[i]);
            }
        }
//        now = new Date();
//        console.log('Elapsed time: ' + (now.getTime() - start.getTime()));
    }

    //! Source for retrieving the positioning information
    PositionSource {
        id: positionSource

        //! Desired interval between updates in milliseconds
        updateInterval: 10000
        active: false

        //! When position changed, update the location strings
        onPositionChanged: {
            if (!positionReceived) { // First time we receive a position, go to it.
                positionReceived = true
                // Keep coordinates in a different object to avoid map auto-centering.
                currentCoord.longitude = positionSource.position.coordinate.longitude;
                currentCoord.latitude = positionSource.position.coordinate.latitude;
                map.center = currentCoord;
                printStations();
            }          
        }
    }

    function startGeolocation() {
        findMe = true;
        positionSource.start();
    }

    function stopGeolocation() {
        findMe = false;
        positionSource.stop();
    }

    Image {
        source: "image://theme/icon-m-toolbar-back"
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 5
        anchors.bottomMargin: 11
        MouseArea {
            anchors.fill: parent
            onClicked: {
                stopGeolocation();
                pageStack.pop();
            }
        }
    }

    Image {
        source: findMe ? "icons/radar.png" : "icons/radar_bw.png"
        x: parent.width - 60
        y: parent.height - 60 - pub.height
        sourceSize.height: 51
        sourceSize.width: 51
        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (!findMe) {
                    startGeolocation();
                }
                else {
                    stopGeolocation();
                }
            }
        }
    }

    Image {
        source: positionReceived ? "icons/center_position.png" : "icons/center_position_bw.png"
        x: parent.width - 130
        y: parent.height - 60 - pub.height
        sourceSize.height: 51
        sourceSize.width: 51
        visible: findMe

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (positionReceived) {
                    map.center = map.toCoordinate(Qt.point(map.width / 2, map.height / 2));
                    currentCoord.longitude = positionSource.position.coordinate.longitude;
                    currentCoord.latitude = positionSource.position.coordinate.latitude;
                    map.center = currentCoord;
                    printStations();
                }
            }
        }
    }

    Column {
        anchors { bottom: pub.top; bottomMargin: 8; left: parent.left; leftMargin: 8 }
        spacing: 8

        Label {
            id: stationLoadingLabel
            visible: true
            text: "Loading stations..."
        }

        Label {
            id: updatingLabel
            visible: false
            text: "Updating..."
        }

        Rectangle {
            id: longRect
            color: "#FFFFFF"
            height: 36
            width: 256

            Repeater {
                model: station
                delegate: Label {
                    //text: "Vélos : " + availableVal + " ; Places : " + freeVal
                    text: "Bikes: " + available_bikes + " ; Parking: " + available_bike_stands
                }
            }
        }

        Rectangle {
            id: latRect
            color: "#FFFFFF"
            height: 36
            width: 256

            Repeater {
                model: station
                delegate: Label {
                    text: calcDate(last_update)
                }
                onItemAdded: {
                    updatingLabel.visible = false
                }
            }
        }
    }

    AdItem {
        id: pub
        parameters: AdParameters {
            applicationId: "none_BikeMee_Nokia"
            usePositioning: findMe
        }
        showText: false
        scaleAd: true
        retryOnError: true
        width: parent.width - 80
        height: 69
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        //anchors.horizontalCenter: parent.horizontalCenter
        anchors.leftMargin: 8
        anchors.rightMargin: 0
    }


    function calcDate(updated) {
        var now = new Date();
        var elapsedSeconds = (now.getTime() - updated) / 1000;
        var min = Math.floor(elapsedSeconds / 60);
        var sec = Math.floor(elapsedSeconds % 60);
        return "Updated: " + min + " min " + sec + " sec"
    }
}
