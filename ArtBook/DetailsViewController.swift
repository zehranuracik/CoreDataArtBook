import UIKit
import PhotosUI
import CoreData

class DetailsViewController: UIViewController, PHPickerViewControllerDelegate {

    @IBOutlet weak var paintImage: UIImageView!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var artistText: UITextField!
    @IBOutlet weak var yearText: UITextField!
    
    @IBOutlet weak var saveButton: UIButton!
    var chosenPainting = ""
    var chosenPaintingId: UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if chosenPainting != "" {
            saveButton.isHidden = true
            nameText.isEnabled = false
            yearText.isEnabled = false
            artistText.isEnabled = false
            paintImage.isUserInteractionEnabled = false
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Paintings")
            
            if let idString = chosenPaintingId?.uuidString {
                fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
                fetchRequest.returnsObjectsAsFaults = false
                
                do {
                    let results = try context.fetch(fetchRequest)
                    
                    if results.count > 0 {
                        for result in results as! [NSManagedObject] {
                            if let name = result.value(forKey: "name") as? String {
                                nameText.text = name
                            }
                            if let artist = result.value(forKey: "artist") as? String {
                                artistText.text = artist
                            }
                            if let year = result.value(forKey: "year") as? String {
                                yearText.text = year
                            }
                            if let imageData = result.value(forKey: "image") as? Data {
                                let image = UIImage(data: imageData)
                                paintImage.image = image
                            }
                        }
                    }
                } catch {
                    print("Error fetching data: \(error)")
                }
            }
        }
        else {
            paintImage.image = UIImage(named: "select")
            saveButton.isEnabled = false
        }
        


        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(gestureRecognizer)
        
        paintImage.isUserInteractionEnabled = true
        let imageGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(pickImage))
        paintImage.addGestureRecognizer(imageGestureRecognizer)
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
    
    @objc func pickImage() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .images
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        saveButton.isEnabled = trueg
        picker.dismiss(animated: true, completion: nil)
        
        let selectedResult = results.first
        
        selectedResult?.itemProvider.loadObject(ofClass: UIImage.self, completionHandler: { [weak self] (image, error) in
            if let image = image as? UIImage {
                DispatchQueue.main.async {
                    self?.paintImage.image = image
                }
            } else if let error = error {
                print("Error loading image: \(error.localizedDescription)")
            }
        })
    }

    @IBAction func saveButton(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let newPainting = NSEntityDescription.insertNewObject(forEntityName: "Paintings", into: context)
        
        newPainting.setValue(nameText.text, forKey: "name")
        newPainting.setValue(artistText.text, forKey: "artist")
        newPainting.setValue(yearText.text, forKey: "year")
        newPainting.setValue(UUID(), forKey: "id")
        
        if let image = paintImage.image, let data = image.jpegData(compressionQuality: 0.5) {
            newPainting.setValue(data, forKey: "image")
        }
        
        do {
            try context.save()
            print("Saved successfully")
        } catch {
            print("Error saving data: \(error)")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "newData"), object: nil)
        self.navigationController?.popViewController(animated: true)
    }
}
