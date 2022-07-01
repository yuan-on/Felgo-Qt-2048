import Felgo 3.0
import QtQuick 2.2

GameWindow {
    id: gameWindow
    screenWidth: 960
    screenHeight: 640

    property int gridWidth: 300 // width and height of the game grid
    property int gridSizeGame: 4 // game grid size in tiles
    property int gridSizeGameSquared: gridSizeGame*gridSizeGame
    property var emptyCells // an array to keep track of all empty cells
    property var tileItems:  new Array(gridSizeGameSquared) // our Tiles

    activeScene: gameScene

    EntityManager {
        id: entityManager
        entityContainer: gameContainer
    }

    Scene {
        id: gameScene

        width: 480
        height: 320

        Rectangle {
            id: background
            anchors.fill: gameScene.gameWindowAnchorItem
            color: "#2979FF" // main color
            border.width: 5
            border.color: "#4A230B" // margin color
            radius: 10 // radius of the corners
        }
        Item {
            id: gameContainer
            width: gridWidth
            height: width // square so height = width
            anchors.centerIn: parent

            GameBackground {}
        }
        Timer {
            id: moveRelease
            interval: 300
        }
        Keys.forwardTo: keyboardController //  makeing sure that focus is automatically provided to the keyboardController.

        Item {
            id: keyboardController

            Keys.onPressed: {
                if(!system.desktopPlatform)
                    return

                if (event.key === Qt.Key_Left && moveRelease.running === false) {
                    event.accepted = true
                    moveLeft()
                    moveRelease.start()
                    console.log("move Left")
                }
                if (event.key === Qt.Key_Right && moveRelease.running === false) {
                    event.accepted = true
                    moveRight()
                    moveRelease.start()
                    console.log("move Right")
                }
                if (event.key === Qt.Key_Up && moveRelease.running === false) {
                    event.accepted = true
                    moveUp()
                    moveRelease.start()
                    console.log("move Up")
                }
                if (event.key === Qt.Key_Down && moveRelease.running === false) {
                    event.accepted = true
                    moveDown()
                    moveRelease.start()
                    console.log("move Down")
                }
            }
        }
        MouseArea{
            id: mouseArea
            anchors.fill: gameScene.gameWindowAnchorItem

            property int startX //initial position X
            property int startY //initial position Y

            property string direction //of the swipe
            property bool moving: false

            onPressed: {
                startX = mouseX
                startY = mouseY
                moving = false
            }

            onReleased: {
                moving = false
            }

            onPositionChanged: {
                var deltax = mouse.x - startX
                var deltay = mouse.y - startY

                if(moving === false){
                    if(Math.abs(deltax) > 40 || Math.abs(deltay) > 40){
                        moving = true

                        if(deltax > 30 && Math.abs(deltay) < 30 && moveRelease.running === false){
                            console.log("move right")
                            moveRight()
                            moveRelease.start()
                        }
                        else if(deltax < -30 && Math.abs(deltay) < 30 && moveRelease.running === false){
                            console.log("move left")
                            moveLeft()
                            moveRelease.start()
                        }
                        else if(Math.abs(deltax) < 30 && deltay > 30 && moveRelease.running === false){
                            console.log("move down")
                            moveDown()
                            moveRelease.start()
                        }
                        else if(Math.abs(deltax) < 30 && deltay < -30 && moveRelease.running === false){
                            console.log("move up")
                            moveUp()
                            moveRelease.start()
                        }
                    }
                }
            }
        }

        Component.onCompleted: {
            // fill the main array with empty spaces
            for(var i = 0; i < gridSizeGameSquared; i++){
                tileItems[i] = null
            }
            //collect empty cells positions
            updateEmptyCells()
            //create 2 random tiles
            createNewTile()
            createNewTile()
        }
    }

    function updateEmptyCells(){ //extract and save emptyCells from tileItems for later generation of new random tiles
        emptyCells = []
        for(var i = 0; i < gridSizeGameSquared; i++){
            if(tileItems[i] === null){
                emptyCells.push(i)
            }
        }
    }
    function createNewTile(){
        var randomCellId = emptyCells[Math.floor(Math.random() * emptyCells.length)] // get random emptyCells
        var tileId = entityManager.createEntityFromUrlWithProperties(Qt.resolvedUrl("Tile.qml"), {"tileIndex": randomCellId}) //create new Tile with a referenceID
        tileItems[randomCellId] = entityManager.getEntityById(tileId) //paste new Tile to the array
        emptyCells.splice(emptyCells.indexOf(randomCellId), 1) //remove the taken cell from emptyCell array
    }
    function merge(sourceRow){
        var i, j
        var nonEmptyTiles = [] //sourceRow without empty tiles
        var indices = []

        //remove empty elements
        for(i = 0; i < sourceRow.length; i++){
            indices[i] = nonEmptyTiles.length
            if(sourceRow[i] > 0){
                nonEmptyTiles.push(sourceRow[i])
            }
        }

        var mergedRow = [] //row afer merge
        for(i = 0; i < nonEmptyTiles.length; i++){

            if(i === nonEmptyTiles.length - 1){ //if last element push because last element has no other to merge with
                mergedRow.push(nonEmptyTiles[i])
            }
            else{
                //comparing if values are equal/mergeable
                if(nonEmptyTiles[i] === nonEmptyTiles[i+1]){
                    for(j = 0; j < sourceRow.length; j++){
                        if(indices[j] > mergedRow.length){
                            indices[j] -= 1
                        }
                    }

                    //merge elements
                    mergedRow.push(nonEmptyTiles[i] + 1)
                    i++ //skip one element, because one got deleted
                }
                else{
                    mergedRow.push(nonEmptyTiles[i]) //no merge
                }
            }
        }

        //fill empty spots with zeros
        for(i=mergedRow.length; i < sourceRow.length; i++){
            mergedRow[i] = 0
        }
        //create object with merged row array inside and return it
        return {mergedRow : mergedRow, indices: indices}
    }
    function getRowAt(index){
        var row = []
        for(var j = 0; j < gridSizeGame; j++){
            //if there are no titleItems at this spot push(0) to the row, else push the titleIndex value
            if(tileItems[j + index * gridSizeGame] === null){
                row.push(0)
            }
            else{
                row.push(tileItems[j + index * gridSizeGame].tileValue)
            }
        }
        return row
    }
    function moveLeft(){
        var isMoved = false //move happens not for a single cell but for a whole row
        var sourceRow, mergedRow, merger, indices
        var i, j

        for(i = 0; i < gridSizeGame; i++){ //gridSizeGame is 4
            sourceRow = getRowAt(i)
            merger = merge(sourceRow)
            mergedRow = merger.mergedRow
            indices = merger.indices

            //checks if the given row is not the same as before
            if(!arraysIdentical(sourceRow, mergedRow)){
                isMoved = true
                //merges and moves tileItems elements
                for(j = 0; j < sourceRow.length; j++){
                    //checks if an element is not empty
                    if(sourceRow[j] > 0 && indices[j] !== j){
                        //checks if a merge has happened and at what position
                        if(mergedRow[indices[j]] > sourceRow[j] && tileItems[gridSizeGame * i + indices[j]] !== null){
                            //move, merge, increment value of the merged element
                            tileItems[gridSizeGame * i + indices[j]].tileValue++ // incrementing the value of the tile that got merged
                            tileItems[gridSizeGame * i + j].moveTile(gridSizeGame * i + indices[j]) // move second tile in the merge direction(will be visible only when all animations are set up)
                            tileItems[gridSizeGame * i + j].destroyTile()
                        } else{
                            //move only
                            tileItems[gridSizeGame * i + j].moveTile(gridSizeGame * i + indices[j]) // move to the new position
                            tileItems[gridSizeGame * i + indices[j]] = tileItems[gridSizeGame * i + j] //update the element inside the array
                        }
                        tileItems[gridSizeGame * i + j] = null // set to empty an old position of the moved tile
                    }
                }
            }
        }
        if(isMoved){
            //update empty cells
            updateEmptyCells()
            //create new random position tile
            createNewTile()
        }
    }
    function moveRight(){
        var isMoved = false
        var sourceRow, mergedRow, merger, indices
        var i, j, k // k used for reversing

        for(i = 0; i < gridSizeGame; i++) {
            // reverse sourceRow
            sourceRow = getRowAt(i).reverse()
            merger = merge(sourceRow)
            mergedRow = merger.mergedRow
            indices = merger.indices

            if (!arraysIdentical(sourceRow,mergedRow)) {
                isMoved = true
                // reverse all other arrays as well
                sourceRow.reverse()
                mergedRow.reverse()
                indices.reverse()
                // recalculate the indices from the end to the start
                for (j = 0; j < indices.length; j++)
                    indices[j] = gridSizeGame - 1 - indices[j]

                for(j = 0; j < sourceRow.length; j++) {
                    k = sourceRow.length -1 - j

                    if (sourceRow[k] > 0 && indices[k] !== k) {
                        if (mergedRow[indices[k]] > sourceRow[k] && tileItems[gridSizeGame * i + indices[k]] !== null) {
                            // Move and merge
                            tileItems[gridSizeGame * i + indices[k]].tileValue++
                            tileItems[gridSizeGame * i + k].moveTile(gridSizeGame * i + indices[k])
                            tileItems[gridSizeGame * i + k].destroyTile()
                        } else {
                            // Move only
                            tileItems[gridSizeGame * i + k].moveTile(gridSizeGame * i + indices[k])
                            tileItems[gridSizeGame * i + indices[k]] = tileItems[gridSizeGame * i + k]
                        }
                        tileItems[gridSizeGame * i + k] = null
                    }
                }
            }
        }

        if (isMoved) {
            // update empty cells
            updateEmptyCells()
            // create new random position tile
            createNewTile()
        }
    }
    function moveUp() {
        var isMoved = false
        var sourceRow, mergedRow, merger, indices
        var i, j

        for (i = 0; i < gridSizeGame; i++) {
            sourceRow = getColumnAt(i)
            merger = merge(sourceRow)
            mergedRow = merger.mergedRow
            indices = merger.indices

            if (! arraysIdentical(sourceRow,mergedRow)) {
                isMoved = true
                for (j = 0; j < sourceRow.length; j++) {
                    if (sourceRow[j] > 0 && indices[j] !== j) {
                        // keep in mind now we are working with COLUMNS NOT ROWS!
                        // i and j are swapped when arranging tileItems
                        if (mergedRow[indices[j]] > sourceRow[j] && tileItems[gridSizeGame * indices[j] + i] !== null) {
                            // Move and merge
                            tileItems[gridSizeGame * indices[j] + i].tileValue++
                            tileItems[gridSizeGame * j + i].moveTile(gridSizeGame * indices[j] + i)
                            tileItems[gridSizeGame * j + i].destroyTile()
                        } else {
                            // just move
                            tileItems[gridSizeGame * j + i].moveTile(gridSizeGame * indices[j] + i)
                            tileItems[gridSizeGame * indices[j] + i] = tileItems[gridSizeGame * j + i]
                        }
                        tileItems[gridSizeGame * j + i] = null
                    }
                }
            }
        }

        if (isMoved) {
            // update empty cells
            updateEmptyCells()
            // create new random position tile
            createNewTile()
        }
    }
    function moveDown() {
        var isMoved = false
        var sourceRow, mergedRow, merger, indices
        var j, k

        for (var i = 0; i < gridSizeGame; i++) {
            sourceRow = getColumnAt(i).reverse()
            merger = merge(sourceRow)
            mergedRow = merger.mergedRow
            indices = merger.indices

            if (! arraysIdentical(sourceRow,mergedRow)) {
                isMoved = true
                sourceRow.reverse()
                mergedRow.reverse()
                indices.reverse()

                for (j = 0; j < gridSizeGame; j++)
                    indices[j] = gridSizeGame - 1 - indices[j]

                for (j = 0; j < sourceRow.length; j++) {
                    k = sourceRow.length -1 - j

                    if (sourceRow[k] > 0 && indices[k] !== k) {
                        // keep in mind now we are working with COLUMNS NOT ROWS!
                        // i and k will be swapped when arranging tileItems
                        if (mergedRow[indices[k]] > sourceRow[k] && tileItems[gridSizeGame * indices[k] + i] !== null) {
                            // Move and merge
                            tileItems[gridSizeGame * indices[k] + i].tileValue++
                            tileItems[gridSizeGame * k + i].moveTile(gridSizeGame * indices[k] + i)
                            tileItems[gridSizeGame * k + i].destroyTile()

                        } else {
                            // Move only
                            tileItems[gridSizeGame * k + i].moveTile(gridSizeGame * indices[k] + i)
                            tileItems[gridSizeGame * indices[k] + i] = tileItems[gridSizeGame * k + i]
                        }
                        tileItems[gridSizeGame * k + i] = null
                    }
                }
            }
        }

        if (isMoved) {
            // update empty cells
            updateEmptyCells()
            // create new random position tile
            createNewTile()
        }
    }
    function getColumnAt(index){
        var column = []
        for(var j = 0; j < gridSizeGame; j++){
            //if there are no titleItems at this spot push(0) to the column, else push the titleIndex value
            if(tileItems[index + j * gridSizeGame] === null){
                column.push(0)
            }
            else{
                column.push(tileItems[index + j * gridSizeGame].tileValue)
            }
        }
        return column
    }
    function arraysIdentical(a,b){
        var i = a.length
        if(i !== b.length) return false
        while (i--) {
            if(a[i] !== b[i]) return false
        }
        return true
    }

}
