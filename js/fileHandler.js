function downloadFile() {
    var fileContent = editor.getValue();
    // Check that the editor contains non-whitespace characters.
    if (!(fileContent.search(/\S/) === -1)) {
        var element = document.createElement('a');
        element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(fileContent));
        element.setAttribute('download', filename+".lua");

        if (document.createEvent) {
            var event = document.createEvent('MouseEvents');
            event.initEvent('click', true, true);
            element.dispatchEvent(event);
        }
        else {
            element.click();
        }
    } else {
        alert("There's nothing to export.\n\nWrite some code first and then export it.");
    }
}


function uploadFile() {
    var files = this.files;
    if (files.length === 0) {
        return;
    }
    
    var reader = new FileReader();
    reader.onload = function(event) {
        editor.setValue("");
        editor.clearHistory();
        editor.replaceRange( event.target.result, {line: 1} );
    };
    filename = files[0].name;
    
    // Ensure that the user uploaded a .lua file, then update the project fields too.
    if (filename.substring(filename.length-4).toLowerCase() == ".lua") {
        filename = filename.substring(0,filename.length-4);
        document.getElementById( 'project-'+activeProject ).innerHTML = filename;
        projectFilename[activeProject] = filename;
        filenameField.value = filename;
        reader.readAsText(files[0]);
    }
}