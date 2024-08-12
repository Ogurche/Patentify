const uploadBox = document.getElementById('upload-box');

const uploadInput = document.querySelector('#upload-box input[type="file"]');
const fileNameDisplay = document.querySelector('#upload-box #file-name-display');
const uploadSubmit = document.querySelector('#upload-box button[type="submit"]');

updateFileNameDisplay();
uploadInput.addEventListener("change", updateFileNameDisplay);

function updateFileNameDisplay() {
    const curFiles = uploadInput.files;
    if (curFiles.length === 0) {
        fileNameDisplay.textContent = "Файл не выбран";
        uploadSubmit.classList.add('hidden');
    } else {
        const file = curFiles[0];
        fileNameDisplay.textContent = `Файл ${file.name}`;
        uploadSubmit.classList.remove('hidden');
    }
}

uploadBox.addEventListener('submit', (event) => {
    event.preventDefault();

    uploadSubmit.textContent = 'Ожидание...';
    uploadSubmit.disabled = true;

    const renderElement = (elem) => {
        const resultBox = document.getElementById('upload-result');

        resultBox.innerHTML = '';
        resultBox.append(elem);    
    }

    const getErrorMsg = (message) => {
        const errorMsg = document.createElement('div');
        errorMsg.textContent = message;
        errorMsg.classList.add('errortext');
        return errorMsg;
    }

    const getButton = (text, href) => {
        const button = document.createElement('a');
        button.style['text-decoration'] = 'none';
        button.style['font-color'] = 'black';
        button.textContent = text;
        button.href = encodeURIComponent(href);
        button.classList.add('btn', 'btn-highlight');
        return button;
    }

    const getTransitions = (result) => {
        const elem = document.createElement('div');
        elem.classList.add('flex', 'flex-centered');

        elem.append(
            getButton('Скачать обработанный файл', `download/${result.filepath}`),
            getButton('Перейти к аналитике', `analytics/${result.id}`),
        );

        return elem;
    }

    fetch(uploadBox.action, {
        method: uploadBox.method,
        body: new FormData(uploadBox),
    })
    .then(response => response.ok
        ? response.json().then(json => renderElement(getTransitions(json)))
        : response.json().then(json => renderElement(getErrorMsg(json.message)))
    )
    .finally(() => {
        uploadSubmit.textContent = 'Загрузить';
        uploadSubmit.disabled = false;
    });
});
