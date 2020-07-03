// The app calls this function to get the code from the editor.
function getCode() {
    var code = editor.getValue();
    return code;
}

var hasFinalised = false;

// Clearing the editor and loading a new sample project.
function loadCode(target){
    if (typeof sampleProject === 'object' && typeof sampleProject[target] === 'object') {
        editor.setValue("");
        editor.clearHistory();
        editor.replaceRange( sampleProject[target].code, {line: 1} );
        // loadCode() is called when the site finishes loading
        // and the custom event won't be fired at this time.
        if (hasFinalised) {
            console.log("loadCode - finalised")
            // Dispact a custom event to the app to get the new code automatically.
            document.dispatchEvent( new CustomEvent( 'projectSelected' ) )
        } else {
            hasFinalised = true;
            console.log("loadCode - not finalised")
        }
    }
}