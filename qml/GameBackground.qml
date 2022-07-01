import QtQuick 2.2
import Felgo 3.0

// GameBackground is our decorative layer
Rectangle {
  id: gameBackground
  width: gridWidth
  height: width // square so height = width
  color: "#0D47A1"
  radius: 5

  // STATIONARY, IMMOVABLE orange grid
  Grid {
    id: tileGrid
    anchors.centerIn: parent
    rows: gridSizeGame //”4” - in this case we don't need to specify columns because the component will do that for us
    //Repeater fills our gameBackground with empty(orange) tiles
    Repeater {
      id: cells
      model: gridSizeGameSquared //”16” - repeat times


      Item { // an invisible item holds our tile width and height. so we can adjust our margins and offsets
        width: gridWidth / gridSizeGame // ”300” / ”4”
        height: width // square so height=width
        Rectangle {
          anchors.centerIn: parent
          width: parent.width-2 // -2 is our width margin offset. set 0 if no offset needed
          height: width // square so height = width
          color: "#FFFDE7"
          radius: 4
        }
      }
    }
  }
}
