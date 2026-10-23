(function () {
 'use strict';
 var scopes=new WeakMap();
 function normalize(value){return String(value||'').normalize('NFKD').replace(/[\u0300-\u036f\u064b-\u065f\u0670\u0640]/g,'').replace(/[أإآٱ]/g,'ا').replace(/ى/g,'ي').toLocaleLowerCase().replace(/\s+/g,' ').trim();}
 function matches(query,text){var terms=normalize(query).split(' ').filter(Boolean),label=normalize(text);return terms.every(function(term){return label.indexOf(term)!==-1;});}
 function refresh(inputID,tree,predicate){
  var input=document.getElementById(inputID),instance=tree.jstree(true);if(!input||!instance)return;
  if(predicate)scopes.set(input,predicate);var scope=scopes.get(input)||function(){return true;};
  function category(node){return !(node.data&&node.data.isBrand);}
  instance.settings.search.search_callback=function(query,node){return scope(node)&&category(node)&&matches(query,node.text);};
  instance.settings.search.fuzzy=false;
  instance.open_all();instance.search(input.value.trim());
  var query=normalize(input.value),nodes=instance.get_json('#',{flat:true}),visible=new Set(),count=0;
  nodes.forEach(function(node){if(scope(node)&&category(node)&&(!query||matches(query,node.text))){count++;visible.add(node.id);instance.get_node(node.id).parents.forEach(function(id){visible.add(id);});}});
  // Keep nodes and native permission inputs in the form: filtering never redraws or detaches them.
  nodes.forEach(function(node){var element=document.getElementById(node.id);if(element){if(scope(node)&&(!query||visible.has(node.id)))element.style.removeProperty('display');else element.style.display='none';}});
  var status=document.getElementById(inputID+'Results');
  if(!status){status=document.createElement('p');status.id=inputID+'Results';status.className='small text-muted my-2';status.setAttribute('role','status');status.setAttribute('aria-live','polite');(input.closest('.input-group')||input).insertAdjacentElement('afterend',status);}
  status.hidden=!query;status.textContent=count?'التصنيفات المطابقة: '+count:'لا توجد تصنيفات مطابقة.';
 }
 function bind(inputID,tree,predicate){
  var input=document.getElementById(inputID);if(!input)return;if(predicate)scopes.set(input,predicate);if(input.dataset.crmTreeSearchBound)return;
  input.dataset.crmTreeSearchBound='1';var timer;
  input.addEventListener('keydown',function(event){if(event.key==='Enter'){event.preventDefault();clearTimeout(timer);refresh(inputID,tree);}});
  input.addEventListener('input',function(){clearTimeout(timer);timer=setTimeout(function(){refresh(inputID,tree);},150);});
  input.addEventListener('search',function(){clearTimeout(timer);refresh(inputID,tree);});
 }
 window.CRMGuideTreeSearch={bind:bind,refresh:refresh,matches:matches};
}());
