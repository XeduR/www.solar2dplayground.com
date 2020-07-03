// The app calls this function to get the code from the editor.
function getCode() {
    var code = editor.getValue();
    return code;
}

// Clearing the editor and loading a new sample project.
function loadCode(target){
    if (typeof sampleProject === 'object' && typeof sampleProject[target] === 'object') {
        editor.setValue("");
        editor.clearHistory();
        editor.replaceRange( sampleProject[target].code, {line: 1} );
        // Dispact a custom event to the app to get the new code automatically.
        document.dispatchEvent( new CustomEvent( 'projectSelected' ) )
    }
}