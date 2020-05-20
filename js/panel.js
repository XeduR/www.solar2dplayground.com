function closePanel(target) {
    document.getElementById(target).className = "button-header";
    document.getElementById("panel-"+target).style.display = "none";
    resizeEditor();
}

function togglePanel(target){
    var isActive = document.getElementById(target).className.indexOf("active");
    document.getElementById("code").className = "button-header";
    document.getElementById("panel-code").style.display = "none";
    document.getElementById("info").className = "button-header";
    document.getElementById("panel-info").style.display = "none";
    if (isActive === -1) {
        document.getElementById(target).className += " active";
        document.getElementById("panel-"+target).style.display = "block";
    }
    resizeEditor();
}