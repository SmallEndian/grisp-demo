var express = require('express');
let antidoteClient = require('antidote_ts_client')
let antidote = antidoteClient.connect(8087, "localhost")
antidote.defaultBucket = "B"
let counter1 = antidote.counter("A")
var app = express();

let before = "<center><h1 id='nb' style='font-size:1000%'> X = ";

let after = "</h1></center> <script> setTimeout(function(){ document.location.reload(); }, 1000); </script> ";

app.get('/', function (req, res) {

	let Value = 0;
	/*antidote.update([counter1.increment(1) ]).then(resp => Value = counter1.read()); */
	// Here
	//antidote.update([counter1.increment(1)])
	Value = counter1.read().then(K => {
		res.send(before + K + after);

	}).catch( K => {
		res.send(before + "?" + after);
	} );
 //res.send('Hello World! ' + Value);
});

app.listen(3000, function () {
	console.log('Example app listening on port 3000!');
});
