import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './ServerCredentialsWinDCSlide.module.css'

export default function ServerCredentialsWinDCSlide({ index, project }) {
  return (
    <Slide index={index} className={styles.serverCredentialsWinDC}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />

      <div className={`${styles.body} content-frame content-gutter`}>
        <div className={styles.header}>
          <p className={styles.eyebrow}>Step 9</p>
          <h2>Server Credentials — <span className={styles.highlight}>Windows DC</span></h2>
          <p className={styles.subtitle}>
            Add the Windows domain controller credentials for guest discovery
          </p>
        </div>

        <div className={styles.columns}>
          <div className={styles.left}>
            <h3 className={styles.sectionTitle}>Add Credentials</h3>

            <div className={styles.fieldGroup}>
              <div className={styles.field}>
                <span className={styles.fieldLabel}>Operating System</span>
                <span className={styles.fieldValue}>Windows</span>
              </div>
              <div className={styles.field}>
                <span className={styles.fieldLabel}>Domain</span>
                <code className={styles.fieldCode}>migrate.local</code>
              </div>
              <div className={styles.field}>
                <span className={styles.fieldLabel}>Username</span>
                <code className={styles.fieldCode}>Administrator</code>
              </div>
              <div className={styles.field}>
                <span className={styles.fieldLabel}>Password</span>
                <code className={styles.fieldCode}>Windows123!</code>
              </div>
            </div>
          </div>

          <div className={styles.right}>
            <img
              src="/Credentials-windc.png"
              alt="Add credentials for Windows DC"
              className={styles.screenshot}
            />
          </div>
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
