window.playgroundCrashed = {
	reportCrash: function()
	{
        if (typeof parent.playgroundCrash === "function") {
    		return parent.playgroundCrash();
        } else {
			return false;
        }
	}
}
