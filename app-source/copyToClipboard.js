window.copyToClipboard = {
	copy: function(msg)
	{
		const element = document.createElement('textarea');
        element.value = msg;
        element.setAttribute('readonly', '');
        element.style.position = 'absolute';
        element.style.left = '-9999px';
        document.body.appendChild(element);
        element.select();
        document.execCommand('copy');
        document.body.removeChild(element);
		return true;
	}
}