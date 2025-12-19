import { Controller } from "@hotwired/stimulus"

let dropzone

export default class extends Controller {
  static targets = ["input", "dropzone"]
  static values = {
    title: String,
    redirectUrl: String,
    redirectTitle: String
  }

  connect() {
    this.dragCounter = 0
    this.overlay = null
    
    // Bind event handlers to document
    this.boundDragenter = this.dragenter.bind(this)
    this.boundDragover = this.dragover.bind(this)
    this.boundDragleave = this.dragleave.bind(this)
    this.boundDrop = this.drop.bind(this)
    
    document.addEventListener("dragenter", this.boundDragenter)
    document.addEventListener("dragover", this.boundDragover)
    document.addEventListener("dragleave", this.boundDragleave)
    document.addEventListener("drop", this.boundDrop)
    
    this.loadPendingFile()
  }
  
  disconnect() {
    document.removeEventListener("dragenter", this.boundDragenter)
    document.removeEventListener("dragover", this.boundDragover)
    document.removeEventListener("dragleave", this.boundDragleave)
    document.removeEventListener("drop", this.boundDrop)
  }

  get isActive() {
    return this.hasInputTarget || this.hasRedirectUrlValue
  }

  get dropzoneTitle() {
    if (this.hasInputTarget) {
      return this.inputTarget.dataset.dropzoneTitle || "Drop file here"
    }
    return this.redirectTitleValue || "Drop CSV to create batch"
  }

  loadPendingFile() {
    if (!this.hasInputTarget) return

    const pendingFile = sessionStorage.getItem("dropzone_pending_file")
    const pendingFileName = sessionStorage.getItem("dropzone_pending_filename")
    const pendingFileType = sessionStorage.getItem("dropzone_pending_filetype")

    if (pendingFile && pendingFileName) {
      const byteString = atob(pendingFile)
      const ab = new ArrayBuffer(byteString.length)
      const ia = new Uint8Array(ab)
      for (let i = 0; i < byteString.length; i++) {
        ia[i] = byteString.charCodeAt(i)
      }
      const blob = new Blob([ab], { type: pendingFileType || "text/csv" })
      const file = new File([blob], pendingFileName, { type: pendingFileType || "text/csv" })

      const dataTransfer = new DataTransfer()
      dataTransfer.items.add(file)
      this.inputTarget.files = dataTransfer.files
      this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))

      sessionStorage.removeItem("dropzone_pending_file")
      sessionStorage.removeItem("dropzone_pending_filename")
      sessionStorage.removeItem("dropzone_pending_filetype")
    }
  }

  dragenter(event) {
    if (!this.isActive) return

    event.preventDefault()
    this.dragCounter++

    if (this.dragCounter === 1) {
      this.showDropzone()
    }
  }

  dragover(event) {
    if (!this.isActive) return
    event.preventDefault()
  }

  dragleave(event) {
    if (!this.isActive) return

    event.preventDefault()
    this.dragCounter--

    if (this.dragCounter === 0) {
      this.hideDropzone()
    }
  }

  drop(event) {
    if (!this.isActive) return

    event.preventDefault()
    this.dragCounter = 0
    this.hideDropzone()

    const files = event.dataTransfer?.files
    if (!files?.length) return

    if (this.hasInputTarget) {
      this.inputTarget.files = files
      this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
    } else if (this.hasRedirectUrlValue) {
      const file = files[0]
      const reader = new FileReader()
      reader.onload = () => {
        const base64 = btoa(
          new Uint8Array(reader.result).reduce((data, byte) => data + String.fromCharCode(byte), "")
        )
        sessionStorage.setItem("dropzone_pending_file", base64)
        sessionStorage.setItem("dropzone_pending_filename", file.name)
        sessionStorage.setItem("dropzone_pending_filetype", file.type)
        window.location.href = this.redirectUrlValue
      }
      reader.readAsArrayBuffer(file)
    }
  }

  showDropzone() {
    if (this.hasDropzoneTarget) {
      this.dropzoneTarget.classList.add('dropzone')
      return
    }

    if (!dropzone) {
      dropzone = document.createElement('div')
      dropzone.classList.add('file-dropzone')

      const title = document.createElement('h1')
      title.innerText = this.dropzoneTitle
      dropzone.appendChild(title)

      document.documentElement.appendChild(dropzone)
      document.body.style.overflow = 'hidden'

      window.getComputedStyle(dropzone).opacity
      dropzone.classList.add('visible')
    }
  }

  hideDropzone() {
    if (this.hasDropzoneTarget) {
      this.dropzoneTarget.classList.remove('dropzone')
      return
    }

    if (dropzone) {
      dropzone.remove()
      dropzone = undefined
      document.body.style.overflow = 'auto'
    }
  }
}
