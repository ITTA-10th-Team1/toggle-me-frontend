// Run after flutter build web: Node.js 22+, CHROME_BIN optional. Uses local guest room only.
const fs = require('node:fs');
const path = require('node:path');
const http = require('node:http');
const {spawn} = require('node:child_process');
const root = path.resolve('build/web');
const out = path.resolve('build/desk-web-smoke');
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

 const guest='http://127.0.0.1:8769/#/room?guest=1';
 const load=async()=>{
   await send('Page.navigate',{url:'about:blank'});
   await send('Page.navigate',{url:guest});
   let ready=false;
   for(let i=0;i<100;i++){ready=await evaluate("document.querySelector('iframe')?.contentDocument?.querySelector('model-viewer')?.loaded===true");if(ready)break;await sleep(300);}
   if(!ready)throw Error('Room model did not load');await sleep(800);
 };
 const surfacePoints=async()=>JSON.parse(await evaluate(`JSON.stringify((()=>{
   const f=document.querySelector('iframe'),r=f.contentDocument.querySelector('model-viewer'),j=r.originalGltfJson,rect=f.getBoundingClientRect();
   const groups={};
   const visit=(i,set)=>{const n=j.nodes[i];if(Number.isInteger(n.mesh))set.add(n.mesh);for(const c of n.children||[])visit(c,set);};
   for(const name of ['stand','body','desk','Chair assembly']){const i=j.nodes.findIndex(n=>n.name===name);const set=new Set();visit(i,set);groups[name]=set;}
   const found={};
   for(let y=15;y<rect.height-10;y+=8)for(let x=15;x<rect.width-10;x+=8){const hit=r.surfaceFromPoint(x,y);if(typeof hit!=='string')continue;const mesh=Number.parseInt(hit,10);for(const [name,set] of Object.entries(groups))if(set.has(mesh)&&!found[name])found[name]={x:x+rect.x,y:y+rect.y,mesh};}
   return found;
 })())`));
 for(const [root,code] of [['stand','mirror'],['body','fridge'],['desk','desk'],['Chair assembly','desk']]) {
   await load();
   if(root==='stand')await screenshot('room-mobile');
   const points=await surfacePoints();const point=points[root];if(!point)throw Error('No visible hit for '+root);
   await evaluate("window.__roomEvents=[];window.addEventListener('message',e=>{try{const d=JSON.parse(e.data);if(d.channel==='RoomFurniture')window.__roomEvents.push(d.value)}catch{}})");
   await tap(point.x,point.y);await sleep(400);
   const events=await evaluate('window.__roomEvents');if(!events.includes(code))throw Error('Tap not forwarded for '+root);
   await evaluate("document.querySelector('flt-semantics-placeholder')?.click()");await sleep(300);
   const login=await evaluate("Boolean(document.querySelector('[aria-label=\"카카오 로그인\"]'))");if(!login)throw Error('Flutter did not handle '+code);
   console.log(JSON.stringify({root,code,point,login}));
 }
 await load();
 const layout=JSON.parse(fs.readFileSync('docs/desk-backend-layout.json','utf8'));
 const old=Object.entries(layout.preservedNodes).map(([name,n],index)=>({furnitureTypeId:index+1,furnitureTypeCode:name==='stand'?'mirror':'fridge',objectNodeName:name,position:{x:n.translation[0],y:n.translation[1],z:n.translation[2]},rotationQuaternion:{x:n.rotation[0],y:n.rotation[1],z:n.rotation[2],w:n.rotation[3]},scale:{x:n.scale[0],y:n.scale[1],z:n.scale[2]},renderOrder:index+1,hidden:false}));
 for(const [mode,placements] of [['legacy',old],['all',[...old,layout.roomFurniture]],['hidden',[...old,{...layout.roomFurniture,hidden:true}]]]) {
   const encoded=JSON.stringify(placements);
   await evaluate(`document.querySelector('iframe').srcdoc=document.querySelector('iframe').srcdoc.replace('const placements = null;',${JSON.stringify('const placements = '+encoded+';')})`);
   await sleep(2500);
   const state=JSON.parse(await evaluate("JSON.stringify((()=>{const r=document.querySelector('iframe').contentDocument.querySelector('model-viewer');const k=Object.getOwnPropertySymbols(r).find(s=>s.description==='scene');const scene=r[k];let desk;scene.traverse(n=>{if(n.name==='desk')desk=n});return {loaded:r.loaded,deskVisible:desk.visible,position:desk.position.toArray(),scale:desk.scale.toArray()}})())"));
   console.log(JSON.stringify({mode,...state}));
   if(!state.loaded||state.deskVisible!==(mode==='all'))throw Error('Server placement mismatch '+mode);
   if(mode==='all')await screenshot('server-room-mobile');
   // Reset the document before testing the next server response.
   await load();
 }
 await send('Page.navigate',{url:'about:blank'});
 await send('Page.navigate',{url:'http://127.0.0.1:8769/#/items/create'});
 await sleep(3000);
 await send('Input.dispatchMouseEvent',{type:'mouseWheel',x:200,y:155,deltaY:0,deltaX:400});
 await sleep(700);await screenshot('desk-category');
 if(errors.length)throw Error('Browser exceptions: '+errors.join(','));
 console.log(JSON.stringify({passed:true,errors}));
 await send('Browser.close').catch(()=>{});
 } finally {if(ws)ws.close();chrome.kill();server.close();}
})().catch(e=>{console.error(e);process.exitCode=1;server.close();});
