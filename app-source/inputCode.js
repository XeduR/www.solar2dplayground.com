window.inputCode = {
	getCode: function()
	{
        if (typeof parent.getCode === "function") {
    		return parent.getCode();
        } else {
			return false;
        }
	},
	addEventListener: function( listenerReference ) {
        let f = LuaCreateFunction( listenerReference )
        document.addEventListener( "inputCode", function() { f() } )
    }
}
