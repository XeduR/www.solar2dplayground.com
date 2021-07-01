window.versionInfo = 
{
	// Outputs the Solar2D build version to browser console when the playground launches.
	output: function( buildVersion ){
        // Original code by Qugurun, source:
        // https://github.com/Qugurun/Solar2D/tree/main/html5%20console%20show%20logo
        var styles = [
            'background: #ffcc01; font: bold 16px Arial',
            'background: #ff6601; font: bold 16px Arial',
            'background: #ff8001; font: bold 16px Arial',
            'background: #ff9901; font: bold 16px Arial',
            'background: #ffb301; font: bold 16px Arial',
            'background: #57507f; font: bold 16px Arial',
            'font: bold 14px Arial; color: #FF6906',
            'font: bold 12px Arial; color: #FFFFFF',
        ];

        console.log( '%c %c %c %c %c %c %c  SOLAR2D PLAYGROUND%c v' + buildVersion + '  %c %c %c %c %c %c %c',
            styles[0], styles[1], styles[2], styles[3], styles[4], styles[5], styles[6], styles[7],
            styles[0], styles[1], styles[2], styles[3], styles[4], styles[5], styles[6]
        );
	}
};
