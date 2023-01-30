

  const widgetDiv = document.querySelector(".spotlight-widget");
  const query = "<%= search_rdf_url(spotlight: @spotlight.id, format: :json, limit:5) %>"

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
      // const im = document.createElement("img");
      // im.src = entity.image;
    
      li.innerHTML=`<img src="${entity.image}"><div class="list-item"><div class="item-title">${entity.title}</div><div class="item-description">${trimmedString}</div></div>`;
      // li.appendChild(im);

    
     
    });
     widgetDiv.appendChild(ul);
});