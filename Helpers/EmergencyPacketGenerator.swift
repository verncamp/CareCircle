//
//  EmergencyPacketGenerator.swift
//  CareCircle
//
//  Generates a shareable PDF with critical care info:
//  profile, medications, conditions, emergency contacts,
//  insurance, and physician details.
//

import UIKit
import SwiftData

struct EmergencyPacketGenerator {

    static func generate(for profile: ParentProfile) -> Data {
        let pageWidth: CGFloat = 612   // US Letter
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        let contentWidth = pageWidth - margin * 2

        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), [
            kCGPDFContextTitle as String: "Emergency Packet — \(profile.name)",
            kCGPDFContextCreator as String: "CareCircle"
        ])

        UIGraphicsBeginPDFPage()
        var y: CGFloat = margin

        // Title
        y = drawText("EMERGENCY CARE PACKET", at: y, margin: margin, width: contentWidth,
                      font: .boldSystemFont(ofSize: 22), color: UIColor(red: 0.2, green: 0.6, blue: 0.6, alpha: 1))

        // Generated date
        y = drawText("Generated \(Date().formatted(date: .long, time: .shortened))",
                      at: y, margin: margin, width: contentWidth,
                      font: .systemFont(ofSize: 10), color: .gray)
        y += 16

        // Divider
        y = drawDivider(at: y, margin: margin, width: contentWidth)
        y += 12

        // Parent Info
        y = drawSectionHeader("PATIENT INFORMATION", at: y, margin: margin, width: contentWidth)

        y = drawField("Name", value: profile.name, at: y, margin: margin, width: contentWidth)

        if let dob = profile.dateOfBirth {
            let age = Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? 0
            y = drawField("Date of Birth", value: "\(dob.formatted(date: .long, time: .omitted)) (Age \(age))",
                          at: y, margin: margin, width: contentWidth)
        }

        if let bt = profile.bloodType, !bt.isEmpty {
            y = drawField("Blood Type", value: bt, at: y, margin: margin, width: contentWidth)
        }

        if let allergies = profile.allergies, !allergies.isEmpty {
            y = drawField("⚠ Allergies", value: allergies, at: y, margin: margin, width: contentWidth)
        }
        y += 8

        // Medical
        y = drawSectionHeader("MEDICAL TEAM", at: y, margin: margin, width: contentWidth)

        if let doc = profile.primaryPhysician, !doc.isEmpty {
            y = drawField("Primary Physician", value: doc, at: y, margin: margin, width: contentWidth)
        }
        if let ins = profile.insuranceProvider, !ins.isEmpty {
            var insText = ins
            if let num = profile.insuranceNumber, !num.isEmpty {
                insText += " (#\(num))"
            }
            y = drawField("Insurance", value: insText, at: y, margin: margin, width: contentWidth)
        }
        if let pharm = profile.pharmacyName, !pharm.isEmpty {
            var pharmText = pharm
            if let phone = profile.pharmacyPhone, !phone.isEmpty {
                pharmText += " — \(phone)"
            }
            y = drawField("Pharmacy", value: pharmText, at: y, margin: margin, width: contentWidth)
        }
        y += 8

        // Medications
        if !profile.medications.isEmpty {
            y = drawSectionHeader("CURRENT MEDICATIONS", at: y, margin: margin, width: contentWidth)

            for med in profile.medications {
                var line = "• \(med.name)"
                if !med.dosage.isEmpty { line += " — \(med.dosage)" }
                if !med.frequency.isEmpty { line += " (\(med.frequency))" }
                y = drawText(line, at: y, margin: margin, width: contentWidth,
                             font: .systemFont(ofSize: 12), color: .darkText)

                // Check for page break
                if y > pageHeight - margin - 40 {
                    UIGraphicsBeginPDFPage()
                    y = margin
                }
            }
            y += 8
        }

        // Conditions
        if !profile.conditions.isEmpty {
            y = drawSectionHeader("DIAGNOSED CONDITIONS", at: y, margin: margin, width: contentWidth)

            let conditionText = profile.conditions.joined(separator: ", ")
            y = drawText(conditionText, at: y, margin: margin, width: contentWidth,
                         font: .systemFont(ofSize: 12), color: .darkText)
            y += 8
        }

        // Emergency Contacts
        y = drawSectionHeader("EMERGENCY CONTACTS", at: y, margin: margin, width: contentWidth)

        if let name = profile.emergencyContactName, !name.isEmpty {
            var contactText = name
            if let phone = profile.emergencyContactPhone, !phone.isEmpty {
                contactText += " — \(phone)"
            }
            y = drawField("Emergency Contact", value: contactText, at: y, margin: margin, width: contentWidth)
        }

        // Family members
        for member in profile.familyMembers {
            var memberText = "\(member.name) (\(member.role.rawValue))"
            if let phone = member.phoneNumber, !phone.isEmpty {
                memberText += " — \(phone)"
            }
            y = drawText("• \(memberText)", at: y, margin: margin, width: contentWidth,
                         font: .systemFont(ofSize: 11), color: .darkGray)

            if y > pageHeight - margin - 40 {
                UIGraphicsBeginPDFPage()
                y = margin
            }
        }

        y += 20
        y = drawDivider(at: y, margin: margin, width: contentWidth)
        y += 8

        _ = drawText("Generated by CareCircle • Keep this document accessible for emergency responders",
                     at: y, margin: margin, width: contentWidth,
                     font: .italicSystemFont(ofSize: 9), color: .gray)

        UIGraphicsEndPDFContext()
        return pdfData as Data
    }

    // MARK: - Drawing Helpers

    @discardableResult
    private static func drawText(_ text: String, at y: CGFloat, margin: CGFloat, width: CGFloat,
                                  font: UIFont, color: UIColor) -> CGFloat {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ]
        let rect = CGRect(x: margin, y: y, width: width, height: .greatestFiniteMagnitude)
        let boundingRect = (text as NSString).boundingRect(with: rect.size, options: .usesLineFragmentOrigin,
                                                            attributes: attributes, context: nil)
        (text as NSString).draw(in: CGRect(x: margin, y: y, width: width, height: boundingRect.height),
                                withAttributes: attributes)
        return y + boundingRect.height + 4
    }

    @discardableResult
    private static func drawSectionHeader(_ text: String, at y: CGFloat, margin: CGFloat, width: CGFloat) -> CGFloat {
        let newY = drawText(text, at: y, margin: margin, width: width,
                            font: .boldSystemFont(ofSize: 13),
                            color: UIColor(red: 0.2, green: 0.6, blue: 0.6, alpha: 1))
        return newY + 2
    }

    @discardableResult
    private static func drawField(_ label: String, value: String, at y: CGFloat, margin: CGFloat, width: CGFloat) -> CGFloat {
        let labelFont = UIFont.boldSystemFont(ofSize: 11)
        let valueFont = UIFont.systemFont(ofSize: 12)

        let labelAttrs: [NSAttributedString.Key: Any] = [.font: labelFont, .foregroundColor: UIColor.gray]
        let valueAttrs: [NSAttributedString.Key: Any] = [.font: valueFont, .foregroundColor: UIColor.darkText]

        let labelSize = (label as NSString).size(withAttributes: labelAttrs)
        (label as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: labelAttrs)
        let valueRect = CGRect(x: margin + labelSize.width + 8, y: y, width: width - labelSize.width - 8, height: 40)
        (value as NSString).draw(in: valueRect, withAttributes: valueAttrs)

        return y + max(labelSize.height, 16) + 6
    }

    @discardableResult
    private static func drawDivider(at y: CGFloat, margin: CGFloat, width: CGFloat) -> CGFloat {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: y))
        path.addLine(to: CGPoint(x: margin + width, y: y))
        UIColor.lightGray.setStroke()
        path.lineWidth = 0.5
        path.stroke()
        return y + 1
    }
}
