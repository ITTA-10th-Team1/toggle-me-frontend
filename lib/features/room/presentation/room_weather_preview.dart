/// Manual weather demo; no location, API calls, or persistent settings.
const roomWeatherPreview = r"""
(() => {
  const style = document.createElement('style');
  style.textContent = `
    #weather-controls {position:absolute;top:8px;left:50%;transform:translateX(-50%);z-index:3;display:flex;gap:6px;padding:6px;border-radius:24px;background:rgba(255,250,241,.94);box-shadow:0 2px 12px #49332214;font:14px sans-serif;white-space:nowrap}
    #weather-controls button {border:1px solid #dfd6cb;background:white;color:#514438;border-radius:18px;min-height:40px;padding:0 14px;cursor:pointer;font:inherit}
    #weather-controls button[aria-pressed=true] {background:#ff8738;color:white;border-color:#ff8738}
    #weather-controls button:focus-visible {outline:3px solid #487fc2;outline-offset:2px}
    #weather-layer {position:absolute;inset:0;overflow:hidden;pointer-events:none;z-index:2;border-radius:16px}
    #weather-layer i {position:absolute;top:-25px;will-change:transform;animation:weather-fall linear infinite}
    #weather-layer[data-mode=rain] {background:linear-gradient(#849fb512,transparent)}
    #weather-layer[data-mode=rain] i {width:1.5px;height:19px;border-radius:2px;background:linear-gradient(transparent,#6596bcaa)}
    #weather-layer[data-mode=snow] i {width:6px;height:6px;border-radius:50%;background:#fff;box-shadow:0 0 3px #b1c8dc;animation-name:weather-snow}
    @keyframes weather-fall {to {transform:translate(-65px,var(--fall))}}
    @keyframes weather-snow {50% {transform:translate(20px,calc(var(--fall) * .5))}to {transform:translate(-15px,var(--fall))}}
  `;
  document.head.append(style);
  const layer = document.createElement('div');
  layer.id = 'weather-layer'; layer.setAttribute('aria-hidden','true');
  const controls = document.createElement('div'); controls.id='weather-controls';
  controls.setAttribute('role','group'); controls.setAttribute('aria-label','날씨 효과 체험');
  const resize = () => layer.style.setProperty('--fall',(innerHeight+50)+'px');
  resize(); addEventListener('resize',resize);
  const setMode = mode => {
    layer.dataset.mode = mode; layer.replaceChildren();
    controls.querySelectorAll('button').forEach(b => b.setAttribute('aria-pressed',String(b.dataset.mode===mode)));
    if (mode==='off') return;
    const count = mode==='rain' ? 65 : 40;
    for (let i=0;i<count;i++) {
      const particle=document.createElement('i');
      particle.style.left=(Math.random()*115)+'%';
      const seconds=mode==='rain' ? .7+Math.random()*.5 : 5+Math.random()*5;
      particle.style.animationDuration=seconds+'s';
      particle.style.animationDelay=(-Math.random()*seconds)+'s';
      particle.style.opacity=String(.35+Math.random()*.6);
      if(mode==='snow') {const size=3+Math.random()*5;particle.style.width=size+'px';particle.style.height=size+'px';}
      layer.append(particle);
    }
  };
  for(const [mode,label] of [['rain','비'],['snow','눈'],['off','끄기']]) {
    const button=document.createElement('button');button.type='button';button.textContent=label;button.dataset.mode=mode;
    button.addEventListener('click',()=>setMode(mode));controls.append(button);
  }
  document.body.append(layer,controls);setMode('off');
})();
""";
