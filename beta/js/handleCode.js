// The app calls this function to get the code from the editor.
function getCode() {
    var code = editor.getValue();
    return code;
}

var hasFinalised = false;

// Clearing the editor and loading a new custom or sample projects.
function loadCode(target,type,customNum) {
    var buttonImport = document.getElementById("import");
    var isImportDisabled = buttonImport.disabled;
    filenameField.value = projectFilename[target];
    filename = projectFilename[target];
    activeProject = target;
    isCustomProject = false;
    
    if (type === "custom") {
        buttonImport.disabled = false;
        filenameField.disabled = false;
        if (isImportDisabled) {
            document.getElementById("button-import").classList.remove("disabled");
        }
        editor.setValue("");
        editor.clearHistory();
        isCustomProject = true;
        activeCustomProject = customNum;
        editor.replaceRange( customProject[customNum], {line: 1} );
    } else {
        buttonImport.disabled = true;
        filenameField.disabled = true;
        if (!isImportDisabled) {;
            document.getElementById("button-import").classList.add("disabled");
        }
        if (typeof sampleProject === 'object' && typeof sampleProject[target] === 'object') {
            editor.setValue("");
            editor.clearHistory();
            editor.replaceRange( sampleProject[target].code, {line: 1} );
            // loadCode() is called when the site finishes loading and the custom event won't be fired at this time.
            if (hasFinalised) {
                // Dispatch a custom event to the app to get the new code automatically.
                frames[0].playgroundApp.dispatchEvent( new CustomEvent( 'inputCode' ) )
            } else {
                if (typeof frames[0].playgroundApp !== "undefined") {
                    hasFinalised = true;
                }
            }
        }
    }
}