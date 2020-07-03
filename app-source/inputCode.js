window.inputCode = {
	getCode: function()
	{
        if (typeof parent.getCode === "function") {
    		return parent.getCode();
        } else {
            console.log( "Solar2D Playground can't be run directly. You need to run it via Iframe." );
			return false;
        }
	},
	addEventListener: function( listenerReference ) {
        let f = LuaCreateFunction( listenerReference )
        document.addEventListener( "projectSelected", function() { f() })
    }
}
