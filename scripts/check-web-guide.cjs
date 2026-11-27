// Run after flutter build web: Node.js 22+, CHROME_BIN optional. Uses local guest room only.
const fs = require('node:fs');
const path = require('node:path');
const http = require('node:http');
const {spawn} = require('node:child_process');
const root = path.resolve('build/web');
const out = path.resolve('build/guide-web-smoke');
fs.mkdirSync(out,{recursive:true});
if(!fs.existsSync(path.join(root,'index.html')))throw Error('Build the Flutter web app first.');
const types = {'.html':'text/html','.js':'text/javascript','.json':'application/json','.wasm':'application/wasm','.png':'image/png','.webp':'image/webp','.ttf':'font/ttf','.otf':'font/otf','.glb':'model/gltf-binary'};
const server = http.createServer((req,res)=>{
 const file = path.resolve(root, '.'+decodeURIComponent(req.url.split('?')[0] === '/' ? '/index.html' : req.url.split('?')[0]));
 if (!file.startsWith(root+path.sep)) {res.writeHead(403).end();return;}
 fs.readFile(file,(err,data)=>{if(err){res.writeHead(404).end();return;}res.writeHead(200,{'Content-Type':types[path.extname(file)]||'application/octet-stream'});res.end(data);});
});
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
(async()=>{
 await new Promise(r=>server.listen(8769,'127.0.0.1',r));
 const chrome=spawn(process.env.CHROME_BIN || (process.platform==='win32'?'C:/Program Files/Google/Chrome/Application/chrome.exe':'google-chrome'),['--headless=new','--no-sandbox','--disable-crash-reporter','--disable-breakpad','--no-first-run','--no-default-browser-check','--enable-unsafe-swiftshader','--remote-debugging-port=8768','--user-data-dir='+path.join(out,'profile-'+Date.now()),'about:blank'],{windowsHide:true,stdio:'ignore'});
 let ws;
 try {
 let pages;
 for(let i=0;i<60;i++){try{pages=await(await fetch('http://127.0.0.1:8768/json/list')).json();break;}catch{await sleep(200);}}
 if(!pages)throw Error('Chrome did not start');
 ws=new WebSocket(pages.find(p=>p.type==='page').webSocketDebuggerUrl);
 await new Promise((r,j)=>{ws.onopen=r;ws.onerror=j;});
 let id=0;const pending=new Map();let errors=[];
 ws.onmessage=({data})=>{const m=JSON.parse(data);if(m.id){const p=pending.get(m.id);pending.delete(m.id);if(m.error)p.reject(m.error);else p.resolve(m.result);}else if(m.method==='Runtime.exceptionThrown')errors.push(m.params.exceptionDetails.text);};
 const send=(method,params={})=>new Promise((resolve,reject)=>{const n=++id;pending.set(n,{resolve,reject});ws.send(JSON.stringify({id:n,method,params}));});
 await send('Page.enable');await send('Runtime.enable');
 await send('Emulation.setDeviceMetricsOverride',{width:412,height:915,deviceScaleFactor:1,mobile:true});
 const evaluate=async expression=>(await send('Runtime.evaluate',{expression,returnByValue:true})).result.value;
 const tap=async(x,y)=>{
  await send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x,y,radiusX:1,radiusY:1}]});
  await send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
  await sleep(400);
 };
 const screenshot=async name=>{const shot=await send('Page.captureScreenshot',{format:'png',captureBeyondViewport:false});fs.writeFileSync(path.join(out,name+'.png'),Buffer.from(shot.data,'base64'));};
 await send('Page.navigate',{url:'http://127.0.0.1:8769/#/room?guest=1'});
 for(let i=0;i<60;i++){if(await evaluate("Boolean(document.querySelector('iframe')?.contentDocument?.querySelector('model-viewer')?.loaded)"))break;await sleep(500);}
 await sleep(1000);
 await evaluate("window.__iframeDowns=0;document.querySelector('iframe').contentDocument.addEventListener('pointerdown',()=>window.__iframeDowns++);");
 await tap(144,30);
 await screenshot('opened');
 const before=await evaluate("JSON.stringify({pointerEvents:document.querySelector('iframe').style.pointerEvents,hit:document.elementFromPoint(206,690)?.tagName})");
 await tap(206,690);
 await screenshot('next');
 const swallowed=await evaluate('window.__iframeDowns');
 console.log(JSON.stringify({before:JSON.parse(before),iframePointerDowns:swallowed,errors}));
 if(swallowed)throw Error('Tutorial touch reached the 3D iframe');
 await tap(113,690); // previous, back to page one
 await screenshot('previous');
 await tap(206,690);
 for(let i=0;i<3;i++)await tap(247,690);
 await screenshot('last');
 await tap(247,690);
 await screenshot('closed');
 const restored=await evaluate("document.querySelector('iframe').style.pointerEvents");
 await tap(100,500);
 await screenshot('furniture-opened');
 // GoRouter's imperative push need not update location.hash. Assert the actual
 // destination semantics only after all pointer interactions have been tested.
 await evaluate("document.querySelector('flt-semantics-placeholder')?.click()");
 await sleep(500);
 const login=await evaluate("Boolean(document.querySelector('[aria-label=\"카카오 로그인\"]'))");
 console.log(JSON.stringify({restored,login,errors}));
 if(restored!=='auto'||!login||errors.length)throw Error('Furniture interaction did not resume');
 await send('Browser.close').catch(()=>{});
 } finally {if(ws)ws.close();chrome.kill();server.close();}
})().catch(e=>{console.error(e);process.exitCode=1;server.close();});
