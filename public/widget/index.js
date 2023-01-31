const widgetDiv = document.querySelector(".spotlight-widget");
const limit = widgetDiv.dataset.limit;
const endpoint = widgetDiv.dataset.endpoint;
const locale = widgetDiv.dataset.locale;
 const spotlight = widgetDiv.dataset.spotlight;

const query = `${endpoint}/${locale}/search_rdf.json?spotlight=${spotlight}&limit=${limit}`; 

async function loadSpotlight() {
  const res = await fetch(query);
  const json = await res.json();
  return json
}

loadSpotlight().then(entities => {
   console.log(entities);
   const ul=document.createElement('ul');
   ul.classList.add("list-group");
   entities.forEach((entity) => {
    const length = 46;
    const trimmedString = entity.description.length > length ? 
                  entity.description.substring(0, length - 3) + "..." : 
                  entity.description;
    const li = document.createElement("li");
    ul.appendChild(li);
    li.innerHTML=`<img src="${entity.image}"><div class="list-item"><div class="item-title">${entity.title}</div><div class="item-description">${trimmedString}</div></div>`;
  });
   widgetDiv.appendChild(ul);
});