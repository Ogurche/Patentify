const ssnInput = document.querySelector('#ssn-search-box input[type="text"]');
const ssnSearch = document.querySelector('#ssn-search-box button');

ssnSearch.addEventListener("click", (event) => {
    event.preventDefault();
    
    const value = ssnInput.value;
    if (value === "") return;

    ssnSearch.textContent = "Ожидание..."
    ssnSearch.disabled = true;

    fetch(`/search/?inn=${value}`, {method: 'GET'})
    .then(response => response.ok ? response.json() : Promise.reject(response))
    .then(json => renderElement(getTable(json.data, value)))
    .catch(response => response.json().then(json => renderElement(getErrorMsg(json.message))))
    .finally(() => {
        ssnSearch.textContent = 'Найти';
        ssnSearch.disabled = false;
    });
});

function renderElement(elem) {
    const resultBox = document.getElementById('ssn-search-result');

    resultBox.innerHTML = '';
    resultBox.append(elem);
}

function getErrorMsg(message) {
    const errorMsg = document.createElement('div');
    errorMsg.textContent = message;
    errorMsg.classList.add('errortext');
    return errorMsg;
}

function getCell(text) {
    const td = document.createElement('td');
    td.textContent = String(text);
    return td;
}

function getHeader(text) {
    const th = document.createElement('th');
    th.textContent = String(text);
    return th;
}

function getRow(dataRow, inn) {
    const patentTypeText = (num) => {
        if (num === null) return "";
        switch (num) {
            case 1:
                return 'Изобретение';
            case 2:
                return 'Полезная модель';
            case 3:
                return 'Промышленные образцы';        
            default:
                return '';
        }
    }

    const id = (v) => v ? v : 'Нет данных';

    const columns = [
        {field: 'patent_type', cb: patentTypeText},
        {field: 'reg_number', cb: id},
        {field: 'model_name', cb: id},
        {field: 'author', cb: id},
        {field: 'inn', cb: (_) => inn},
        {field: 'address', cb: id},
    ];

    const tr = document.createElement('tr');
    tr.append(...columns.map(col => getCell(col.cb(dataRow[col.field]))));
    return tr;    
}

function getTable(data, inn) {
    if (data.length === 0) {
        return getErrorMsg('Соответствующий патентообладатель не обнаружен');
    }

    const headers = [
        'Patent type',
        'Registration number',
        'Patent Name',
        'Patent Assignee',
        'Tax ID',
        'Registration Address',
    ];

    const card = document.createElement('div');
    card.classList.add('card', 'bg-white');

    const table = document.createElement('table');

    const tr = document.createElement('tr');
    tr.append(...headers.map(getHeader));

    table.append(tr);
    table.append(...data.map(row => getRow(row, inn)));

    card.append(table)

    return card;
}
