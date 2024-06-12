const input = document.querySelector('#upload-box input[type="file"]');
const fileNameDisplay = document.querySelector('#upload-box #file-name-display');
const submit = document.querySelector('#upload-box button[type="submit"]');

updateFileNameDisplay();
input.addEventListener("change", updateFileNameDisplay);

function updateFileNameDisplay() {
    const curFiles = input.files;
    if (curFiles.length === 0) {
        fileNameDisplay.textContent = "Файл не выбран";
        submit.style.display = 'none';
    } else {
        const file = curFiles[0];
        fileNameDisplay.textContent = `Файл ${file.name}`;
        submit.style.display = 'inline';
    }
}

const dropZone = document.querySelector('.upload-section');
dropZone.addEventListener("drop", dropHandler);
dropZone.addEventListener("dragover", ev => { ev.preventDefault(); });
dropZone.addEventListener("dragenter", ev => { ev.preventDefault(); });

function dropHandler(event) {
    event.preventDefault();

    let files = [];

    if (event.dataTransfer.items) {
        for (const item of event.dataTransfer.items) {
            if (item.kind === "file") {
                files.push(item.getAsFile());
            }
        }
    } else {
        for (const file of event.dataTransfer.files) {
            files.push(file);
        }
    }

    if (files.length !== 0) {
        const dT = new DataTransfer();
        dT.items.add(files[0]);
        input.files = dT.files;
        updateFileNameDisplay();
    }
}
